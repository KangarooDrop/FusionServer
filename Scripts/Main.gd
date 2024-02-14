extends Node

var players : Dictionary = {}

const TIME_TO_CHOOSE_BOARD : int = 10
const TIME_TO_CHOOSE_DECK : int = 10

var timeEndBoard : int = -1
var timeEndDeck : int = -1

var boardVotes : Dictionary = {}
var validBoards : Array = []
var chosenBoard = null

var chosenDecks : Dictionary = {}
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
			if chosenBoard == null:
				if Util.getTimeAbsolute() >= timeEndBoard:
					chooseBoard()
			else:
				if not isDecksDecided and Util.getTimeAbsolute() >= timeEndDeck:
					decksDecided()
		GAME_STATE.IN_GAME:
			pass
		GAME_STATE.AFTER_GAME:
			pass

func onPlayerConnect(playerID : int) -> void:
	players[playerID] = PlayerObject.new(playerID)

func onPlayerDisconnect(playerID : int) -> void:
	players.erase(playerID)
	if players.size() <= 1:
		Server.disconnectAndQuit()

func onPlayerReconnect(oldID : int, newID : int) -> void:
	pass

func onAllConnected():
	setGameState(GAME_STATE.BEFORE_GAME)

####################################################################################################

enum GAME_STATE {CONNECTING, BEFORE_GAME, IN_GAME, AFTER_GAME}
enum PHASE {START, DRAW, BET, ACTION, REVEAL, INVADE, END}

var gameState : GAME_STATE = GAME_STATE.CONNECTING
var phase : PHASE = PHASE.END

func setGameState(gameState : GAME_STATE) -> void:
	if gameState == GAME_STATE.BEFORE_GAME:
		rpc("boardAllReceived", validBoards)
		rpc("setBoardVotes", {}, players.size())
		timeEndBoard = Util.getTimeAbsolute() + TIME_TO_CHOOSE_BOARD
		rpc("syncTimerReceived", timeEndBoard)
	elif gameState == GAME_STATE.IN_GAME:
		rpc("gameStarted")
		setPhase(PHASE.START)
	
	self.gameState = gameState

func setPhase(phase : PHASE) -> void:
	if phase == PHASE.START:
		pass

func nextPhase() -> void:
	setPhase((phase + 1) % PHASE.size())

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
###   PRE-GAME   ###

func canVoteBoard() -> bool:
	return gameState == GAME_STATE.BEFORE_GAME and chosenBoard == null

@rpc("any_peer", "call_remote", "reliable")
func onPlayerBoardVote(index : int) -> void:
	if canVoteBoard():
		var playerID : int = multiplayer.get_remote_sender_id()
		print("Received board vote: " + str(playerID) + " >> " + str(index))
		boardVotes[playerID] = index
		rpc("setBoardVotes", getVotesByID(), players.size())
		#if boardVotes.size() >= players.size():
		#	chooseBoard()

func getVotesByID() -> Dictionary:
	var votesByID : Dictionary = {}
	for playerID in boardVotes.keys():
		if not votesByID.has(boardVotes[playerID]):
			votesByID[boardVotes[playerID]] = 1
		else:
			votesByID[boardVotes[playerID]] += 1
	return votesByID

func chooseBoard() -> void:
	print("Choosing board")
	var boardChoices : Array = []
	if boardVotes.size() == 0:
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
	
	var index : int = randi() % validBoards.size()
	if index == 0:
		boardVotes.clear()
		chooseBoard()
		return
	
	chosenBoard = validBoards[index]
	rpc("onBoardChosen", chosenBoard)
	
	timeEndDeck = Util.getTimeAbsolute() + TIME_TO_CHOOSE_DECK
	rpc("syncTimerReceived", timeEndDeck)

func canSelectDeck() -> bool:
	return gameState == GAME_STATE.BEFORE_GAME

@rpc("any_peer", "call_remote", "reliable")
func deckSelected(deckData : Dictionary) -> void:
	var playerID : int = multiplayer.get_remote_sender_id()
	if Validator.validateDeck(deckData) and canSelectDeck():
		print("Received deck data from ", playerID)
		chosenDecks[playerID] = deckData
	else:
		rpc_id(playerID, "onDeckRejected")

func decksDecided():
	for playerID in players.keys():
		if not chosenDecks.has(playerID):
			onConcedeLocal(playerID)
			print("ERROR: No deck data for " + str(playerID))
		else:
			players[playerID].deck.deserialize(chosenDecks[playerID])
	
	print("STARTING GAME!")
	setGameState(GAME_STATE.IN_GAME)

####################################################################################################
###   IN-GAME   ###

####################################################################################################
###   DUMMY FUNCTIONS FOR RPC   ###

@rpc("authority", "call_remote", "reliable")
func onQuitAnswered():
	pass

@rpc("authority", "call_remote", "reliable")
func onGetOpponentElements(elements : Array):
	pass

@rpc("authority", "call_remote", "reliable")
func syncTimerReceived(timeOnEnd : int):
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
