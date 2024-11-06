#shuffle_numbers.py

import shuffler
import itertools
import random

#generate possible combinations of 5 numbers between 0 and 9
combos = []
for item in itertools.combinations(range(0, 10), 5):
  combos.append(item)

#find 4 combos with an equal amount of each number
quit = False
while not quit:
    #randomly select 4
    blocks = []
    all_items = []
    for i in range(4):
        choice = random.choice(combos)
        blocks.append(choice)
        all_items += choice

    success = True
    counts = []
    for j in range(0, 10):
        counts.append(all_items.count(j))


    if len(set(counts)) == 1:
        quit = True

#double up on each block
stimList = []

for block in blocks:
    stimuli = shuffler.ListAdder(list(block), 2).shuffle()
    stimList.append(stimuli)

#now, generate the quiz items and quiz_answers
quiz_items = []
quiz_answers = []

for stim in stimList:
    true_false = [1, 1, 2, 2, 2]
    random.shuffle(true_false)
    for q in true_false[:2]:
        if q == 1:
            quiz_items.append(random.choice(stim))
            quiz_answers.append(q)
        else:
            quit = False
            while not quit:
                item = random.choice(range(0,10))
                if item not in stim and item not in quiz_items:
                    quiz_items.append(item)
                    quiz_answers.append(q)
                    quit = True

print stimList, quiz_items, quiz_answers
