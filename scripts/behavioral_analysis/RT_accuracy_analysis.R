library("ggplot2")
library("dplyr")
library(lme4)
library("tidyverse")
library("lattice")
library("effsize")



subjlist_dir="<path to the subject list folder>"
session_name_1 = "<session 1 subject list name, eg., subjectlist_localizers_session_1.csv>"
session_name_2 = "<session 2 subject list name, eg., subjectlist_localizers_session_2.csv>"
orig_dir = "<raw behavioral data folder on server>"
dest_dir = "<local behavioral analysis working folder>/"

subj_df_1 = read.csv(paste(subjlist_dir, session_name_1, sep=""),header=T, sep=",")
subj_df_2 = read.csv(paste(subjlist_dir, session_name_2, sep=""),header=T, sep=",")
conditions = c("letter_2")

for (subj in 1:length(subj_df$PID)) {
  PID = sprintf("%04.f",subj_df$PID[subj]) 
  VISIT = subj_df$visit[subj]
  SESSION = subj_df$session[subj]
  for (cond in 1:length(conditions))
  orig_folder_dir = paste(orig_dir,PID,"/visit",VISIT, "/session",SESSION,"/fmri/", conditions[cond], "/behavioral/",sep="")
  orig_file_dir = paste(orig_folder_dir,dir(orig_folder_dir,pattern = ".csv"),sep="")
  dest_file_dir = paste(dest_dir,PID,"/visit",VISIT, "/session",SESSION,"/fmri/", conditions[cond], "/behavioral/", sep="")
  dir.create(dest_file_dir, recursive = T)
  file.copy(orig_file_dir, dest_file_dir, 
            overwrite = TRUE, recursive = FALSE, 
            copy.mode = TRUE)

}

data_summary = c()

for (subj in 1:length(subj_df_1$PID)) {
  PID = sprintf("%04.f",subj_df_1$PID[subj]) 
  VISIT1 = subj_df_1$visit[subj]
  SESSION1 = subj_df_1$session[subj]
  VISIT2 = subj_df_2$visit[subj]
  SESSION2 = subj_df_2$session[subj]
  
  letter_folder_dir_1 = paste(dest_dir,PID,"/visit",VISIT1, "/session",SESSION1,"/fmri/letter_1/behavioral/", sep="")
  letter_file_dir_1 = paste(letter_folder_dir_1,dir(letter_folder_dir_1,pattern = ".csv"),sep="")
  
  letter_folder_dir_2 = paste(dest_dir,PID,"/visit",VISIT2, "/session",SESSION2,"/fmri/letter_2/behavioral/", sep="")
  letter_file_dir_2 = paste(letter_folder_dir_2,dir(letter_folder_dir_2,pattern = ".csv"),sep="")
  
  number_folder_dir_1 = paste(dest_dir,PID,"/visit",VISIT1, "/session",SESSION1,"/fmri/number_1/behavioral/", sep="")
  number_file_dir_1 = paste(number_folder_dir_1,dir(number_folder_dir_1,pattern = ".csv"),sep="")
  
  number_folder_dir_2 = paste(dest_dir,PID,"/visit",VISIT2, "/session",SESSION2,"/fmri/number_2/behavioral/", sep="")
  number_file_dir_2 = paste(number_folder_dir_2,dir(number_folder_dir_2,pattern = ".csv"),sep="")
  
  letter_session1_df = read.csv(letter_file_dir_1,header=T, sep=",")
  letter_session2_df = read.csv(letter_file_dir_2,header=T, sep=",")
  number_session1_df = read.csv(number_file_dir_1,header=T, sep=",")
  number_session2_df = read.csv(number_file_dir_2,header=T, sep=",")
  letter_condition = rbind(letter_session1_df[letter_session1_df$block == "quiz",],letter_session2_df[letter_session2_df$block == "quiz",])
  number_condition = rbind(number_session1_df[number_session1_df$block == "quiz",],number_session2_df[number_session2_df$block == "quiz",])
  
  data_summary = rbind(data_summary,letter_condition,number_condition)
}
write.csv(data_summary,file="<ideal file name.csv>",quote = FALSE, row.names = F, col.names = T); # save the data

data_summary_new = data_summary

# re-code inconsistent responses
acc_recoded = c()
for (i in 1:dim(data_summary_new)[1]) {
  if (data_summary_new$RESP[i] == 7) {
    data_summary_new$RESP[i] = 1
  } else if (data_summary_new$RESP[i] == 8) {
    data_summary_new$RESP[i] = 2
  }
  if (data_summary_new$s_id[i]==317 & data_summary_new$RESP[i] == 2) {
    data_summary_new$RESP[i] = 1
  }
  if (data_summary_new$RESP[i] == 3) {
    data_summary_new$RESP[i] = 2
  }
  if (data_summary_new$CRESP[i] == data_summary_new$RESP[i]) {
    acc_recoded[i] = 1
  } else {
    acc_recoded[i] = 0
  }
  
}

data_summary_new=cbind(data_summary_new, acc_recoded)


df_summary_rt = data_summary_new %>% 
  group_by(s_id,experiment) %>% 
  summarize(Mean = mean(RT, na.rm=TRUE))

x = df_summary_rt[df_summary_rt$experiment=="letter",]
y = df_summary_rt[df_summary_rt$experiment=="number",]
t.test(x$Mean, y$Mean, paired = TRUE, alternative = "two.sided")
cohen.d(as.numeric(x$Mean), as.numeric(y$Mean))

df_rt_tbl = df_summary_rt %>% 
  group_by(experiment) %>%
  summarize(
  mean = mean(Mean),
  sd = sd(Mean),
  n = n(),
  se = sd / sqrt(n)
)

df_summary_acc = data_summary_new %>% 
  group_by(s_id,experiment) %>% 
  summarize(Mean = mean(acc_recoded, na.rm=TRUE))

x = df_summary_acc[df_summary_acc$experiment=="letter",]
y = df_summary_acc[df_summary_acc$experiment=="number",]
t.test(x$Mean, y$Mean, paired = TRUE, alternative = "two.sided")
cohen.d(as.numeric(x$Mean), as.numeric(y$Mean))

df_acc_tbl = df_summary_acc %>% 
  group_by(experiment) %>%
  summarize(
    mean = mean(Mean),
    sd = sd(Mean),
    n = n(),
    se = sd / sqrt(n)
  )





# RT

model_mixed_rt = lmer(RT ~ experiment + (1 | s_id), data = data_summary_new)
summary(model_mixed_rt)
confint(model_mixed_rt)
plot(model_mixed_rt, type = c("p", "smooth"))


qqmath(model_mixed_rt, id = 0.05)

# boxplot
p1 = ggplot(df_rt_tbl, aes(x = experiment, y = mean, fill=experiment)) + 
  geom_bar(stat="identity",width = 0.5) +
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.2,
                position=position_dodge(.9)) +
  scale_fill_brewer(palette="Set2") +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  theme(axis.text.x = element_text(angle =20,hjust = 1))+
  ylab("Response Times (sec)") +
  xlab(" ")+ 
  scale_y_continuous(limits = c(0,1.5), expand = c(0, 0))+ 
  theme(text = element_text(size=20))

# bargraph
p2= ggplot(df_summary_rt, aes(x = experiment, y = Mean, fill=experiment)) + 
  # geom_violin() +
  geom_boxplot(width=0.5) +
  scale_fill_brewer(palette="Set2") +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  theme(axis.text.x = element_text(angle =20,hjust = 1))+
  ylab("Response Times (sec)") +
  xlab(" ")+ 
  # geom_jitter(shape=1, position=position_jitter(0.1))+
  theme(text = element_text(size=20))

 

# ACC
model_mixed_acc = lmer(ACC ~ experiment + (1 | s_id), data = data_summary_new)
summary(model_mixed_acc)
confint(model_mixed_acc)
plot(model_mixed_acc, type = c("p", "smooth"))

library("lattice")
qqmath(model_mixed_acc, id = 0.05)

# barplot
p3 = ggplot(df_acc_tbl, aes(x = experiment, y = mean, fill=experiment)) + 
  geom_bar(stat="identity",width = 0.5) +
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se), width=.2,
                position=position_dodge(.9)) +
  scale_fill_brewer(palette="Set2") +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  theme(axis.text.x = element_text(angle =20,hjust = 1))+
  ylab("Accuracy") +
  xlab(" ")+ 
  scale_y_continuous(limits = c(0,1), expand = c(0, 0))+ 
  theme(text = element_text(size=20))

# boxplot
p4 = ggplot(df_summary_acc, aes(x = experiment, y = Mean, fill=experiment)) + 
  # geom_violin() +
  geom_boxplot(width=0.5) +
  scale_fill_brewer(palette="Set2") +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_line(colour = "black")) +
  theme(axis.text.x = element_text(angle =20,hjust = 1))+
  ylab("Accuracy") +
  xlab(" ")+
  # geom_jitter(shape=1, position=position_jitter(0.1))+
  theme(text = element_text(size=20))

ggsave("Stanford_behavioral_ACC_barplot.png",p3,device="png",dpi=600,width=4, height=4)

