extends Node

var players : Dictionary = {}

const TIME_TO_CHOOSE_BOARD : int = 1000
const TIME_TO_CHOOSE_DECK : int = 10
const TIME_TO_CHOOSE_BET : int = 2000
const TIME_TO_CHOOSE_ACTION : int = 30
const TIME_TO_CHOOSE_REVEALS : int = 30
const TIME_TO_RESOLVE : int = 30

func _ready():
	Connector.connect("player_connected", self.onPlayerConnect)
	Connector.connect("player_disconnected", self.onPlayerDisconnect)
	Connector.connect("player_reconnected", self.onPlayerReconnect)
	Connector.connect("all_connected", self.onAllConnected)
	validBoards = getAllBoards()

func _process(delta):
	match gameState:
		GAME_STATE.CONNECTING:
			pass
		GAME_STATE.BEFORE_GAME:
			processBeforeGame(delta)
		GAME_STATE.IN_GAME:
			processInGame(delta)
		GAME_STATE.AFTER_GAME:
			pass

func onPlayerConnect(playerID : int) -> void:
	print("Player: " + str(playerID) + " connected")
	players[playerID] = PlayerObject.new(playerID, Color.RED, "_NO_NAME")
	for id in players.keys():
		rpc_id(id, "playerAdded", id == playerID, players[playerID].playerID, players[playerID].color, players[playerID].username)

func onPlayerDisconnect(playerID : int) -> void:
	print("Player: " + str(playerID) + " dc'd")
	rpc("playerRemoved", playerID)
	players.erase(playerID)
	if players.size() <= 1:
		Server.disconnectAndQuit()

func onPlayerReconnect(oldID : int, newID : int) -> void:
	print("Player: " + str(oldID) + " reconnected as " + str(newID))
	rpc("playerReconnected", oldID, newID)

func onAllConnected():
	setGameState(GAME_STATE.BEFORE_GAME)

####################################################################################################
###   BEFORE-GAME   ###

var timeEndBoard : int = -1
var timeEndDeck : int = -1

var boardVotes : Dictionary = {}
var boardVoteConfirmed : Array = []
var validBoards : Array = []
var chosenBoard = null

var chosenDecks : Dictionary = {}
var chosenDeckConfirmed : Array = []
var isDecksDecided : bool = false

func getAllBoards() -> Array:
	var boards : Array = ["random"]
	for fn in FileIO.getAllFiles(FileIO.BOARD_PATH):
		var path : String = FileIO.BOARD_PATH + fn
		var data : Dictionary = FileIO.readJson(path)
		var error : int = Validator.validateBoard(data) 
		if error == Validator.BOARD_CODE.OK:
			boards.append(data)
		else:
			print("ERROR: Could not validate path ", error)
	return boards

func canVoteBoard() -> bool:
	return gameState == GAME_STATE.BEFORE_GAME and chosenBoard == null

func getVotesByID() -> Dictionary:
	var votesByID : Dictionary = {}
	for playerID in boardVotes.keys():
		if not votesByID.has(boardVotes[playerID]):
			votesByID[boardVotes[playerID]] = 1
		else:
			votesByID[boardVotes[playerID]] += 1
	return votesByID

@rpc("any_peer", "call_remote", "reliable")
func onPlayerBoardVote(index : int) -> void:
	if canVoteBoard():
		var playerID : int = multiplayer.get_remote_sender_id()
		print("Received board vote: " + str(playerID) + " >> " + str(index))
		boardVotes[playerID] = index
		rpc("setBoardVotes", getVotesByID(), players.size())

@rpc("any_peer", "call_remote", "reliable")
func onBoardVoteConfirmed():
	if canVoteBoard():
		var playerID : int = multiplayer.get_remote_sender_id()
		if not playerID in boardVoteConfirmed:
			boardVoteConfirmed.append(playerID)
			if boardVoteConfirmed.size() >= players.size():
				chooseBoard()

func chooseBoard(fromRandom : bool = false) -> void:
	if not fromRandom:
		print("Choosing board")
	var boardChoices : Array = []
	if boardVotes.size() == 0:
		if not fromRandom:
			print("No board votes. Choosing random.")
		boardChoices = validBoards
	else:
		var votesByID : Dictionary = getVotesByID()
		print("Board votes: " + str(votesByID))
		
		var voteBoards : Array = []
		for id in votesByID.keys():
			if voteBoards.is_empty() or votesByID[id] > votesByID[voteBoards[0]]:
				voteBoards = [id]
			elif votesByID[id] == votesByID[voteBoards[0]]:
				voteBoards.append(id)
		
		for id in voteBoards:
			boardChoices.append(validBoards[id])
	
	var data = boardChoices[randi() % boardChoices.size()]
	if typeof(data) == TYPE_STRING and data == "random":
		print("Chaos reigns. Choosing random.")
		validBoards.erase("random")
		boardVotes.clear()
		chooseBoard(true)
		return
	
	chosenBoard = data
	boardData = BoardDataServer.new()
	boardData.loadSaveData(chosenBoard)
	boardData.setPlayers(players.keys())
	rpc("onBoardChosen")
	
	timeEndDeck = Util.getTimeAbsolute() + TIME_TO_CHOOSE_DECK
	rpc("syncTimerReceived", timeEndDeck)

func canSelectDeck() -> bool:
	return gameState == GAME_STATE.BEFORE_GAME

@rpc("any_peer", "call_remote", "reliable")
func deckSelected(deckData : Dictionary) -> void:
	if canSelectDeck():
		var playerID : int = multiplayer.get_remote_sender_id()
		if Validator.validateDeck(deckData) and canSelectDeck():
			print("Received deck data from ", playerID)
			chosenDecks[playerID] = deckData
		else:
			rpc_id(playerID, "onDeckRejected")

@rpc("any_peer", "call_remote", "reliable")
func onDeckConfirmed() -> void:
	if canSelectDeck():
		var playerID : int = multiplayer.get_remote_sender_id()
		if not playerID in chosenDeckConfirmed:
			chosenDeckConfirmed.append(playerID)
			if chosenDeckConfirmed.size() == players.size():
				decksDecided()

func decksDecided():
	for playerID in players.keys():
		if not chosenDecks.has(playerID):
			onConcedeLocal(playerID)
			print("ERROR: No deck data for " + str(playerID))
		else:
			players[playerID].deck.deserialize(chosenDecks[playerID])
	
	var allPlayerIDs : Array = players.keys()
	for playerID in allPlayerIDs:
		var elements : Array = players[playerID].deck.getElements()
		for otherID in allPlayerIDs:
			if playerID != otherID:
				rpc_id(otherID, "onSetOpponentElements", playerID, elements)
	
	rpc("setBoardData", chosenBoard)
	
	print("STARTING GAME!")
	setGameState(GAME_STATE.IN_GAME)

func isWaitingForBoardVote() -> bool:
	return chosenBoard == null

func isWaitingForDeck() -> bool:
	return not isDecksDecided

func processBeforeGame(_delta : float) -> void:
	if isWaitingForBoardVote():
		if Util.getTimeAbsolute() >= timeEndBoard:
			chooseBoard()
	elif isWaitingForDeck():
		if Util.getTimeAbsolute() >= timeEndDeck:
			decksDecided()

####################################################################################################

enum GAME_STATE {CONNECTING, BEFORE_GAME, IN_GAME, AFTER_GAME}

var gameState : GAME_STATE = GAME_STATE.CONNECTING
var phase : CardDataBase.PHASE = CardDataBase.PHASE.END

var boardData : BoardDataServer

var abilityStack : Array = []

var doneInitialDraw : bool = false
const initialDrawCount : int = 5

var playerBets : Dictionary = {}
var playerBetConfirmed : Array = []
var timeEndBet : int = -1

var playerActions : Dictionary = {}
var playerActionConfirmed : Array = []
var timeEndAction : int = -1

var playerReveals : Dictionary = {}
var playerRevealConfirmed : Array = []
var timeEndReveal : int = -1

func isWaitingForBets() -> bool:
	return playerBetConfirmed.size() < players.size()

func isWaitingForActions() -> bool:
	return playerActionConfirmed.size() < players.size()

func isWaitingForReveals() -> bool:
	return playerRevealConfirmed.size() < players.size()

func setGameState(gameState : GAME_STATE) -> void:
	if gameState == GAME_STATE.BEFORE_GAME:
		rpc("boardAllReceived", validBoards)
		rpc("setBoardVotes", {}, players.size())
		timeEndBoard = Util.getTimeAbsolute() + TIME_TO_CHOOSE_BOARD
		rpc("syncTimerReceived", timeEndBoard)
	elif gameState == GAME_STATE.IN_GAME:
		rpc("gameStarted")
		setPhase(CardDataBase.PHASE.START)
	
	self.gameState = gameState

func checkStack() -> void:
	while abilityStack.size() > 0:
		var index : int = abilityStack.size()-1
		var ability : AbilityBase = abilityStack[index]
		ability.resolve()
		abilityStack.remove_at(index)

func nextPhase() -> void:
	setPhase((phase + 1) % CardDataBase.PHASE.values().size())

func setPhase(phase : CardDataBase.PHASE) -> void:
	#TODO PROC on end of phase effects
	rpc("endPhaseReceived", phase)
	
	#######################
	
	rpc("beginPhaseReceived", phase)
	
	#TODO PROC on start of phase effects
	if phase == CardDataBase.PHASE.START:
		checkStack()
		call_deferred("nextPhase")
	
	elif phase == CardDataBase.PHASE.DRAW:
		var numToDraw : int = 1
		if not doneInitialDraw:
			numToDraw = initialDrawCount
		for i in range(numToDraw):
			for player in players.values():
				player.deck.draw()
		checkStack()
		call_deferred("nextPhase")
	
	elif phase == CardDataBase.PHASE.BET:
		playerBets.clear()
		playerBetConfirmed.clear()
		for playerID in players.keys():
			var pbs : Array = boardData.getPossibleBets(playerID)
			print("Sending pbs: ", pbs)
			rpc_id(playerID, "readyForBetReceived", pbs)
		timeEndBet = Util.getTimeAbsolute() + TIME_TO_CHOOSE_BET
		rpc("syncTimerReceived", timeEndBet)
	
	elif phase == CardDataBase.PHASE.ACTION:
		playerActions.clear()
		playerActionConfirmed.clear()
		for playerID in players.keys():
			var pas : Dictionary = getPossibleActions(playerID)
			print("Sending pas: ", pas)
			rpc_id(playerID, "readyForActionReceived", pas)
		timeEndAction = Util.getTimeAbsolute() + TIME_TO_CHOOSE_ACTION
		rpc("syncTimerReceived", timeEndAction)
	
	elif phase == CardDataBase.PHASE.REVEAL:
		playerReveals.clear()
		playerRevealConfirmed.clear()
		for playerID in players.keys():
			var prs : Dictionary = getPossibleReveals(playerID)
			print("Sending prs: ", prs)
			rpc_id(playerID, "readyForRevealsReceived", prs)
		timeEndReveal = Util.getTimeAbsolute() + TIME_TO_CHOOSE_REVEALS
		rpc("syncTimerReceived", timeEndReveal)
	
	elif phase == CardDataBase.PHASE.INVADE:
		onInvade()
		call_deferred("nextPhase")
	
	elif phase == CardDataBase.PHASE.END:
		call_deferred("nextPhase")
	
	self.phase = phase

func getPossibleActions(playerID : int) -> Dictionary:
	var rtn : Dictionary = {"wait":true}
	var moves : Dictionary = boardData.getPossibleMoves(playerID)
	rtn["move"] = moves
	var fuses : Dictionary = players[playerID].hand.getPossibleFuses(boardData)
	rtn["fuse"] = fuses
	return rtn

func getPossibleReveals(playerID : int) -> Dictionary:
	var rtn : Dictionary = {}
	rtn["board"] = boardData.getPossibleReveals(playerID)
	rtn["hand"] = players[playerID].hand.getPossibleReveals(boardData)
	return rtn

func processInGame(delta : float) -> void:
	if phase == CardDataBase.PHASE.BET:
		if isWaitingForBets():
			if Util.getTimeAbsolute() >= timeEndBet:
				onBetEnd()
	elif phase == CardDataBase.PHASE.ACTION:
		if isWaitingForActions():
			if Util.getTimeAbsolute() >= timeEndAction:
				onActionEnd()
	elif phase == CardDataBase.PHASE.REVEAL:
		if isWaitingForReveals():
			if Util.getTimeAbsolute() >= timeEndReveal:
				onRevealEnd()

@rpc("any_peer", "call_remote", "reliable")
func onBetSelected(index : int) -> void:
	if isWaitingForBets():
		var playerID : int = multiplayer.get_remote_sender_id()
		playerBets[playerID] = index
		print("Received bet from ", playerID)

@rpc("any_peer", "call_remote", "reliable")
func onBetConfirmed() -> void:
	if isWaitingForBets():
		var playerID : int = multiplayer.get_remote_sender_id()
		if not playerID in playerBetConfirmed:
			playerBetConfirmed.append(playerID)
			if playerBetConfirmed.size() == players.size():
				onBetEnd()

func onBetEnd():
	#TODO Bets
	rpc("allBetsReceived", playerBets)
	nextPhase()

@rpc("any_peer", "call_remote", "reliable")
func onActionSelected(action : Array) -> void:
	if isWaitingForActions():
		var playerID : int = multiplayer.get_remote_sender_id()
		playerActions[playerID] = action
		print("Received action from ", playerID)

@rpc("any_peer", "call_remote", "reliable")
func onActionConfirmed() -> void:
	if isWaitingForActions():
		var playerID : int = multiplayer.get_remote_sender_id()
		if not playerID in playerActionConfirmed:
			playerActionConfirmed.append(playerID)
			if playerActionConfirmed.size() == players.size():
				onActionEnd()

func onActionEnd():
	#TODO Actions
	nextPhase()

@rpc("any_peer", "call_remote", "reliable")
func onRevealSelected(reveals : Array) -> void:
	if isWaitingForReveals():
		var playerID : int = multiplayer.get_remote_sender_id()
		playerReveals[playerID] = reveals
		print("Received action from ", playerID)

@rpc("any_peer", "call_remote", "reliable")
func onRevealConfirmed() -> void:
	if isWaitingForReveals():
		var playerID : int = multiplayer.get_remote_sender_id()
		if not playerID in playerRevealConfirmed:
			playerRevealConfirmed.append(playerID)
			if playerRevealConfirmed.size() == players.size():
				onRevealEnd()

func onRevealEnd():
	#TODO Reveals
	nextPhase()

func onInvade() -> void:
	#TODO Invading
	pass

####################################################################################################
###   ANY TIME   ###

@rpc("any_peer", "call_remote", "reliable")
func onConcede() -> void:
	var playerID : int = multiplayer.get_remote_sender_id()
	print("CONCEDE PRESSED by " + str(playerID))
	onConcedeLocal(playerID)

func onConcedeLocal(playerID : int):
	pass

@rpc("any_peer", "call_remote", "reliable")
func onQuit() -> void:
	var playerID : int = multiplayer.get_remote_sender_id()
	print("QUIT PRESSED by " + str(playerID))
	Server.serverPeer.disconnect_peer(playerID)
	Connector.onPlayerRemove(playerID)

####################################################################################################
###   IN-GAME   ###

####################################################################################################
###   DUMMY FUNCTIONS FOR RPC   ###

@rpc("authority", "call_remote", "reliable")
func onQuitAnswered():
	pass

@rpc("authority", "call_remote", "reliable")
func syncTimerReceived(timeOnEnd : int):
	pass

####################################################################################################

@rpc("authority", "call_remote", "reliable")
func playerAdded(isSelf : bool, playerID : int, color : Color, username : String) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func playerRemoved(playerID : int) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func playerReconnected(oldID : int, newID : int) -> void:
	pass

####################################################################################################

@rpc("authority", "call_remote", "reliable")
func boardAllReceived(boardAllData : Array):
	pass

@rpc("authority", "call_remote", "reliable")
func onBoardChosen(boardData : Dictionary) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func onDeckRejected() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func setBoardVotes(voteData : Dictionary) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func gameStarted() -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func setBoardData(data : Dictionary) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func onSetOpponentElements(playerID : int, elements : Array):
	pass

####################################################################################################

### BET ###
@rpc("authority", "call_remote", "reliable")
func readyForBetReceived(possibleBets : Array) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func allBetsReceived(bets : Dictionary) -> void:
	pass

### ACTION ###
@rpc("authority", "call_remote", "reliable")
func readyForActionReceived(possibleActions : Dictionary) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func allActionsReceived(actions : Dictionary) -> void:
	pass

### REVEAL ###
@rpc("authority", "call_remote", "reliable")
func readyForRevealsReceived(possibleReveals : Dictionary) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func allRevealsReceived(reveals : Dictionary) -> void:
	pass

### ALL PHASES ###
@rpc("authority", "call_remote", "reliable")
func beginPhaseReceived(phase : CardDataBase.PHASE) -> void:
	pass

@rpc("authority", "call_remote", "reliable")
func endPhaseReceived(phase : CardDataBase.PHASE) -> void:
	pass
