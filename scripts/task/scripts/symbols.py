
#symbols.py

#based on Park et al., J Neurosci (2011)
#http://www.ncbi.nlm.nih.gov/pubmed/21273418

import psychopy
from psychopy import core, visual, event
import subject
from common import * 
import glob
import random
import copy
import serial
import numpy
import shuffler
import os
from psychopy.iohub import launchHubServer


#time is in seconds
trial_dur =.5
blank_dur = .1
fix_dur = .5
ins_dur = 3.5
quiz_dur = 3
trials_per_block = 10
text_height = 50
quiz_dur = 3
fixation_between_blocks = 10.2
num_possible = 16.

"""
#speed run for testing purposes
trial_dur = .1
blank_dur = .1
fix_dur = .5
ins_dur = .1
quiz_dur = .1
trials_per_block = 10
text_height = 50
fixation_between_blocks = 10.2
num_possible = 16.
"""


config_data = get_config()

del config_data['stimulus_id']

scan_trigger_port = eval(config_data['Scan Trigger Port'])
config_data['Scan Trigger Port'] = scan_trigger_port[0]

info = {'Subject':666, 'scan_id': '?', 'Session':1, 'Trigger fMRI': 'yes', 'Mode':'words'}

if config_data:
    for key in config_data.keys():
        info[key] = config_data[key]

info = infoGUI(info)
mode = info['Mode']

trigger = info['Trigger fMRI']
if trigger in ['yes', 'y']:
    trigger=True
else:
    trigger=False


iohub_config = {'serial.Serial': dict(name='serial', port=scan_trigger_port[0])}

# start the iohub server and get the keyboard and PST box devices
io = launchHubServer(**iohub_config)
kb = io.devices.keyboard
scanner = io.devices.serial

# initializes data collection for PST box and keyboard
kb.enableEventReporting(True)


#create list of blocks
blocks = [0, 1]
block_order = shuffler.ListAdder(blocks, 8).shuffle()

###CREATE WINDOW
win = visual.Window(size=[1024, 768], units='pix', fullscr=True)
win.setMouseVisible(False)
mouse = event.Mouse(visible=False, newPos=None, win=win)

stimuli=[]
if mode in ['words', 'word']:
    mode = 'word'
    block_labels = ['words', 'checkerboard.png']
    #counterbalance word length / frequency
    block_1 = ["wash","book","welcome","chicken","wire","contest","justice","address","moon","college"]
    block_2 = ["boat","farm","conduct","trouble","journey","hate","coal","instant","student","salt"]
    block_3 = ["private","success","cash","wall","partner","divorce","stomach","village","girl", "tree"]
    block_4 = ["expense","vote","pile","play","talk","average","dirt","safe","captain","rent"]
    block_5 = ["hundred","blanket","mistake","bone","belt","request","plastic","prepare","luck","save"]
    block_6 = ["sell","billion","walk","warm","measure","traffic","neck","tape","hill","shop"]
    block_7 = ["forward","fashion","project","chapter","fire","culture","beef","sink","picture","stop"]
    block_8 = ["thermal","main","process","obvious","coat","benefit","crew","goal","examine","desk"]
    
    word_blocks = [block_1, block_2, block_3, block_4, block_5, block_6, block_7, block_8]
    word_blocks = shuffler.ListAdder(word_blocks,1).shuffle()
    for block in word_blocks:
        shuffled_block = shuffler.ListAdder(block, 1).shuffle()
        for word in shuffled_block:
            stimuli.append(word)
    
    
elif mode in ['equations','equation']:
    mode = 'equation'
    for i in range(1,10):
        for j in range(1, 10):
            stimuli.append("%s + %s = %s" % (i, j, i+j))


    for i in range(1, 10):
        for j in range(1, 10):
            stimuli.append("%s x %s = %s" % (i, j, i*j))
            
    stimuli = shuffler.ListAdder(stimuli, 1).shuffle()

    
    
    
elif mode in ['num','numbers','number']:
    mode = 'number'
    #generates list of numbers
    numbers = [0,1,2,3,4,5,6,7,8,9]
    for i in range (0,10):
        stimuli_2a = [] #random 5 numbers
        stimuli_2b = [] #other 5 numbers not selected
        stimuli_2a = random.sample(numbers,5) #generates list of 5 random numbers
        for n in numbers:
            if n not in stimuli_2a:
                stimuli_2b.append(n) #appends the other 5 numbers
        stimuli_2a = shuffler.ListAdder(stimuli_2a, 2).shuffle()
        stimuli_2b = shuffler.ListAdder(stimuli_2b, 2).shuffle()
        for stimulus in stimuli_2a:
            stimuli.append(stimulus)
        for stimulus in stimuli_2b:
            stimuli.append(stimulus)
            
elif mode in ['l','letter','letters']:
    mode = 'letter'
    temp_stimuli = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
    stimuli = shuffler.ListAdder(temp_stimuli, 4).shuffle()

ins_text = "Here, you will see some stimuli."
prompt = "Did you just see: "

if mode in ['word','equation']:
    checkboard = visual.ImageStim(win, 'images/checkerboard.png', pos=[0,0])
else:
    checkboard = visual.ImageStim(win, 'images/checker_square.png', pos=[0,0])
ins_text_checkerboard = 'Just look at the checkerboard.'

j=0
k=0

quiz_items = []
quiz_answers = []
stimuli_shown = []

#make the quizzes
for block in block_order:
    if block ==1:
        block_items = stimuli
        temp = []
        temp_bandaid = []
        picList = [1,1,2,2,2]
        for i in range(trials_per_block):
            #temp = words that have been shown this block
            stimuli_shown.append(block_items[j])
            temp.append(block_items[j])
            j+=1
        picList = shuffler.ListAdder(picList,1).shuffle()
        temp = shuffler.ListAdder(temp,1).shuffle()


        temp_bandaid.append(block_items[j-1])
        for pic in picList[:2]:
            if pic == 1:
                quiz_items.append(temp.pop())
                quiz_answers.append(pic)
            elif pic == 2:
                quit = False
                while not quit:
                    random_element=random.choice(block_items)
                    if mode != 'number':
                        if random_element not in temp and random_element not in quiz_items and random_element not in temp_bandaid:
                            quiz_items.append(random_element)
                            quiz_answers.append(pic)
                            quit = True
                    else: 
                        if random_element not in temp and random_element not in temp_bandaid:
                            temp_bandaid.append(random_element) #temp_bandaid will be empty for first random_element 
                            quiz_items.append(random_element)
                            quiz_answers.append(pic)
                            quit = True
                   
        temp_bandaid= []


#actually starts running and patieqnt sees something!
###CREATE SUBJECT
datadir = os.path.join('data', info['scan_id'])
sub = subject.Subject(info['Subject'], info['Session'], experiment=mode, dataDir=datadir)
sub.addStatic('scan_id', info['scan_id'])

#create stimuli
ins_text_checkerboard = "Just look at the checkerboard."

###CREATE STIMULI
ins_checkerboard = visual.TextStim(win, "", height =text_height, pos=[0,0])
img = visual.TextStim(win, "", pos=[0,0], height=72)
cross = visual.TextStim(win, "+", pos=[0,0], height=72)
quiz = visual.TextStim(win, "", pos=[0,65], height=50)


msg = Message(win)
msg.send(ins_text, wait=True)

ins_text = "Study the %ss.  After a block of %s %ss, we will show you 2 additional target %ss to see if you recognize them." % (mode, trials_per_block, mode, mode)
msg.send(ins_text, wait = True)
ins_text = "If you recognize the target %ss from the previous block, you will press your index finger. If you do not recognize the target %ss from the previous block, you will press your middle finger." % (mode, mode)
msg.send(ins_text, wait = True)

msg.send("Get Ready...", wait=False)
quit = event.waitKeys(keyList = ['q','escape','space'])
if quit[0] == 'escape' or quit[0]=='q':
    exit()



#initializing counters
i=0
block_num = 1
trial = 1
num_correct = 0.0

if trigger:
    scanner.write(chr(numpy.uint8(128+32+64+1))) 


#initializing clock
clock = core.Clock()
clock.reset()
trial_clock = core.Clock()
trial_clock.reset()
stopwatch = core.Clock()
stopwatch.reset()
cross.draw()
win.flip()
core.wait(6)

for block in block_order:
    #fixation period
    trial_clock.reset()
    """
    for frameN in range (606): 
        if frameN <= 606: #60 frames per second
            cross.draw()
        win.flip()
    """
    fix_start = clock.getTime()
    while trial_clock.getTime() < 10.2: #10.2 s
        key = kb.getEvents()
        if key:
            if key[0].key=='q' or key[0].key=='escape':
                exit()
        cross.draw()
        win.flip()
    
    fix_end = clock.getTime()
    fixation = trial_clock.getTime()
    sub.inputData(trial, "fixation", fixation)
    sub.inputData(trial, "trial_start", fix_start)
    sub.inputData(trial, "trial_end", fix_end)
    sub.inputData(trial, "block", "fixation")
    
    if block ==1:

        #display 10 words or equations
        for counter in range(trials_per_block):
            trial+=1
            stimulus = stimuli_shown.pop()
            sub.inputData(trial, "block", mode)
            sub.inputData(trial, "block_num", block_num)
            sub.inputData(trial, "stimulus", stimulus)
            
            trial_start = clock.getTime()
            
            #displays stimulus 0.5 seconds (500ms)
            img.setText(stimulus)
            img.draw()
            win.flip()
            sub.inputData(trial, "trial_start", clock.getTime())
            trial_clock.reset()
            while trial_clock.getTime() < trial_dur:
                img.draw()
                win.flip()
            sub.inputData(trial, "trial_end", clock.getTime())


            #trial_dur = 
            sub.inputData(trial, "trial_dur", trial_clock.getTime())
            
            
            #displays blank .1 seconds (100 ms)
            img.setText("")
            trial_clock.reset()
            while trial_clock.getTime() < blank_dur:
                img.draw()
                win.flip()
            #print trial_clock.getTime()
            #while trial_clock.getTime() < blank_dur:
            #    pass
            #blank_fixation = trial_clock.getTime() 
            sub.inputData(trial, "blank", trial_clock.getTime())

        #fixation period right before quiz (3.5 seconds)
        #trial_clock.reset()
        
        """
        while trial_clock.getTime() < ins_dur:
            cross.draw()
            win.flip()
        """    
            
        #since we're asking for 2 inputs
        for x in range(0,2):
            trial+=1
            io.clearEvents('serial')
            quiz_item = quiz_items.pop()
            CRESP = quiz_answers.pop()
            sub.inputData(trial, 'stimulus', quiz_item)
            sub.inputData(trial, 'block', 'quiz')
            sub.inputData(trial, 'block_num', block_num)
            event.clearEvents()
            
            trial_clock.reset()
            img.setText(quiz_item)
            quiz.setText(prompt)
            img.draw()
            quiz.draw()
            win.flip()
            
            
            #where input starts
            img_onset = clock.getTime()
            sub.inputData(trial, "trial_start", clock.getTime())
            start_time = clock.getTime()

            #assuming user doesn't respond
            RT = quiz_dur
            
            """
            mouse.clickReset()
            while trial_clock.getTime() < quiz_dur:
                key_input = mouse.getPressed(getTime=True)
                print key_input
                press_time = clock.getTime()
                if key_input[1][0]!= 0.0:
                    press_time = clock.getTime()
                    RT = press_time - start_time
                    key = 1
                    break
                if key_input[1][2]!= 0.0:
                    press_time = clock.getTime()
                    RT = press_time - start_time
                    key = 2
                    break
                else:
                    key = 'NA'
             
              """
            #while loop keeps going until we get input
            kb.clearEvents() # clear event queue
            while trial_clock.getTime() < quiz_dur:
                key = kb.getKeys()
                if key:
                    if key[0].key == 'escape' or key[0].key =='q':
                        exit()
                    else:
                        press_time = clock.getTime()
                        RT = press_time - start_time
                        key = key[0].key
                        break
            
    


            #sees if user answered correctly
            if key ==str(int(CRESP) + 1):
                sub.inputData(trial, "ACC", "1")
                num_correct+=1
            else:
                sub.inputData(trial, "ACC", "0")
            
            sub.inputData(trial, "RT", RT)
            sub.inputData(trial, 'RESP', key)
            sub.inputData(trial, 'CRESP', CRESP)
            
            
            trial_fix_time= (quiz_dur - RT) + fix_dur #sum of the remaining time after the button press
            cross.draw()
            trial_clock.reset()
            while trial_clock.getTime() < trial_fix_time:
                cross.draw()
                win.flip()
            sub.inputData(trial, "trial_end", clock.getTime())
            sub.inputData(trial, "fixation", trial_fix_time)
        trial+=1

    #else, show checkerboard
    else:  
        for i in range(trials_per_block):
            
            trial += 1
            
            sub.inputData(trial, "block", "checkerboard")
            sub.inputData(trial, "block_num", block_num)
            #checkboard.draw()
            #win.flip()
            sub.inputData(trial, "trial_start", clock.getTime())
            trial_clock.reset()
            while trial_clock.getTime() < trial_dur:
                checkboard.draw()
                win.flip()
            sub.inputData(trial, "trial_end", clock.getTime())
            sub.inputData(trial, "trial_dur", trial_clock.getTime())
            
            img.setText("")
            trial_clock.reset()
            while trial_clock.getTime() < blank_dur:
                img.draw()
                win.flip()
            sub.inputData(trial, "blank", trial_clock.getTime())
            
            
            """
            while trial_clock.getTime() < trial_dur: #mild adjustment for input lag
                checkboard.draw()
                win.flip()
            """
            """
            trial_clock.reset()
            img.setText("")
            img.draw()
            win.flip()
            while trial_clock.getTime() < blank_dur:
                pass
            """
      
            #sub.inputData(trial, "trial_start", trial_start)
            #sub.inputData(trial, "trial_end", trial_end)
            #trial_dur = trial_end - trial_start
            #sub.inputData(trial, "trial_dur", trial_clock.getTime())
            #sub.inputData(trial, "blank", blank)
        trial+=1
        
    
    block_num +=1
    sub.printData()

#8 blocks of words/checkboard

msg.send("*", wait = False)
print (stopwatch.getTime())
final_acc = num_correct / num_possible *100.
final_acc = str(final_acc) + "%"
print (final_acc)
# Quit
io.quit()
core.wait(10)
core.quit()