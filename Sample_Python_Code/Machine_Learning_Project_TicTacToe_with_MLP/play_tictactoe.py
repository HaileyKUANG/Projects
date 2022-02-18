# -*- coding: utf-8 -*-
"""
File:   play_tictactoe.py
Author: Hailey KUANG
Date:   Oct.04, 2021
Desc:   TicTacToe for HUMAN vs COMPUTER (Trained MLP Model)
        Need to load "Trained_MLP_mmodel.sav"
"""

""" ==================  Import the Needed packages ======================= """
import random
import numpy as np
import pickle

""" ====================  Import the Trained model ======================= """
## Load Trained MLP Model with 'single label' data
loadedModel = pickle.load(open("Trained_MLP_mmodel.sav", 'rb'))

""" ======================  Function Definitions ========================= """
HUMAN = 'X'
COMPUTER = 'O'

board = [0 for i in range(9)]
winning_pattern = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6],
                  [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

def print_board(board):
    for i in range(0, 8, 3):
        line = ""
        for j in range(0, 3):
            if board[i+j] == 1:
                line += HUMAN
            elif board[i+j] == -1:
                line += COMPUTER
            else:
                line += " "
            line += '|'
        print(line[0:-1])
        if i < 6:
            print("-+-+-")

def get_computer_move(board):
    """
    Predict the next optimal move for COMPUTER
    Based on the trained MLP Model with "single label" data
    Return an integer from 0 to 8
    """
    random.seed()
    # print(board)
    board1 = np.reshape(board, (1, -1))
    rnd = int(loadedModel.predict(board1))
    return rnd

def check_for_win(board, turn):
    """ Check for a win (or a tie)
        Compare to each pattern in winning_pattern[]
        Number the corresponding squares that marked by HUMAN and/or COMPUTER
        1) If the number of the squares for H or C's reaches 3, return a win
        2) If it doesn't, and this is already turn # 9, return a tie.
        3) If neither, return False and continue the game.
    """
    for pattern in winning_pattern:
        score = 0
        if board[pattern[0]] == 0:
            continue
        flg = board[pattern[0]]
        for index in pattern:
            if board[index] == flg:
                score += 1
            else:
                break
            if score == 3:
                if flg == 1:
                    print_board(board)
                    print('Human Win')
                elif flg == -1:
                    print_board(board)
                    print('Computer Win')
                return True
        if turn == 9:
            print('Tie')
            return True

    return False

def play():
    print('\n\nWelcome to TicTacToe with Trained MLP Model!')
    turn = 0
    while True:

        legit = False
        while not legit:
            print_board(board)
            move = input('Your turn! Type a number from 0-8 to indicate where to move: ')

            try:
                move = int(move)
                if move < 0 or move > 8:
                    print('That number is out of range, try again.\n')
                    continue

                if board[move] == 0:
                    board[move] = 1
                    legit = True
                else:
                    print("That place is already filled, try again.")
                    continue
            except ValueError:
                print('That\'s not a valid number, try again.\n')
                continue
        turn += 1
        if check_for_win(board, turn):
            return

        legit = False
        while not legit:
            move = get_computer_move(board)
            if board[move] == 0:
                board[move] = -1
                legit = True
            else:
                continue
        turn += 1
        if check_for_win(board, turn):
            return

""" ==========================  Play the Game ============================ """
# Begin the game:
play()