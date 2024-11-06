import time
import pickle
import os

class Subject:
    def __init__(self, number=666, session="", run="", experiment="unknown", dataDir=""):		
        self.number = number
        self.session = session
        self.run = run
        self.date = time.strftime("%d_%b_%y_%I_%M%p")
        #create dictionary to hold trial results
        self.fname = "%s_%s_%s_%s_%s.csv" % (number, experiment, session, run, self.date)
        self.experiment = experiment

        if dataDir:
            self.fname = os.path.join(dataDir, self.fname)

        self.results = {}
        self.statics = {}

    def addStatic(self, key, value):
        self.statics[key] = value

    #stimulus = image_dict[block].pop()
    #sub.inputData(trial, "stimulus", stimulus)
    def inputData(self, trial, condition, value):
        trial = str(trial)
        if self.results.has_key(trial):
            data = self.results[trial]
            data[condition] = value
            self.results[trial] = data
        else:
            data = {}
            data[condition] = value
            self.results[trial] = data					


    def printData(self):	
        trials = self.results.keys()
        intTrials = []
        for t in trials:
            intTrials.append(int(t))
        intTrials.sort()
        trials = []
        for t in intTrials:
            trials.append(str(t))
        f = open(self.fname, "w")

           #get the trial keys from the first row
        keys = []
        for t in trials:
            tk = self.results[t].keys()
            keys += tk
        trialKeys = list(set(keys))
        trialKeys.sort()

        #construct the header
        header = "s_id,experiment,session,trial"

        staticLine = ""

        if self.statics:
            keys = self.statics.keys()
            keys.sort()
            for k in keys:
                header += ",%s" % k
            staticLine += ",%s" % self.statics[k]

        for tk in trialKeys:
            header += ",%s" % tk
        header += "\n"

        f.write(header)

        #write each trial, filling in blank spaces
        for t in trials:
            line = "%s,%s,%s,%s" % (self.number, self.experiment, self.session, t)
            line += staticLine

            trial = self.results[t]
            for tk in trialKeys:
                if trial.has_key(tk):
                    value = trial[tk]
                else:
                    value = ""
                line += ",%s" % value
            line = line + "\n"
            f.write(line)

        f.close()

    def preserve(self):
        f = open("%s.sub" % self.number, "w")
        pickle.dump(self, f)
        f.close()

