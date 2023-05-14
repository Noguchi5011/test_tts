## General lib
import re
import os
import sys
import glob
from copy import deepcopy

## csv format
import pandas as pd
import csv

def find_log_file(group_name:str):
    '''
    [INPUT]
    group_name:str

    [OUTPUT]
    some log files path : list
    e.g.  
        >> print(logfile_path_list)
        >> ['./log/X_2/X_2/X_2_train.log', 
            './log/X_2/tsukuyomi/tsukuyomi_train.log', 
            './log/X_2/noguchi/noguchi_train.log', 
            './log/X_2/JVS010/JVS010_train.log']
    '''

    target_path = f'./log/{group_name}/*/'
    path_list = glob.glob(target_path)

    logfile_path_list = []
    for path_name in path_list:
        file_path = f'{path_name}*.log'
        logfile_path_list.extend(glob.glob(file_path))

    return logfile_path_list


def format_dataframe(all_epoch_res:list):
    '''
    [INPUT]
    all_epoch_res:list

    [OUTPUT]
    epoch_res_df:pandas dataframe 

    perspective:

        create empty dataframe.
        split text when the pattern [train|valid] is found.(re.split())
        extract some values from splitted text to list. (iter_time=0.014, etc..)(re.findall())

        format some value texts to dataframe. (iter_time=0.014, etc.. -> {iter_time:0.014})


    '''
    df = pd.DataFrame(columns=['discriminator_backward_time',
                                'discriminator_fake_loss',
                                'discriminator_forward_time',
                                'discriminator_loss',
                                'discriminator_optim_step_time',
                                'discriminator_real_loss',
                                'discriminator_train_time',
                                'generator_adv_loss',
                                'generator_backward_time',
                                'generator_dur_loss',
                                'generator_feat_match_loss',
                                'generator_forward_time',
                                'generator_kl_loss',
                                'generator_loss',
                                'generator_mel_loss',
                                'generator_optim_step_time',
                                'generator_train_time',
                                'gpu_max_cached_mem_GB',
                                'iter_time',
                                'optim0_lr0',
                                'optim1_lr0',
                                'time',
                                'total_count',
                                'train_time'])


    for epoch, each_epoch in enumerate(all_epoch_res):

        ## split text
        split_trigger = re.compile(r'\[train\] | \[valid\]| \[att_plot\]')
        split_line = split_trigger.split(each_epoch)
        train_log_loss_text = split_line[1]
        split_loss_list = re.split(", ", split_line[1])

        ## extract VALUE_NAME=VALUE format string
        extract_kv_only = []
        extract_val_and_num = re.compile(r'([a-zA-Z0-9_]*)=([0-9e\.\-]*)')
        for line in split_loss_list:
            extract_kv_only.append(extract_val_and_num.search(line).group(0))
        
        ## split string 
        idx_val_pair_list = []
        for line in extract_kv_only:
            idx_val_pair_list.append(line.split("="))

        
        dataframe_csv = pd.DataFrame(idx_val_pair_list, columns=['metric','value'])
        dataframe_csv['epochs'] = f'epoch-{epoch+1}'
        pivot_dataframe_csv = dataframe_csv.pivot(index='epochs',columns='metric',values='value')
        df = pd.concat([df,pivot_dataframe_csv], ignore_index=False)
          

    return df

def extract_loss(group_name:str):
    '''
    [INPUT]
    group_name:str

    [OUTPUT]

    perspective:

        find file name (tsukuyomi, noguchi, jvs, gourp_name)
        for name in files
            file open 
            extract loss value 
            format with pandas
            save to csv

    '''

    logfile_path_list = find_log_file(group_name)

    for file_path in logfile_path_list:
        ## file open
        with open(file_path) as log_file:
            log_text = log_file.read()
        log_text_line = log_text.split("\n")

        ## search each epoch result line
        all_epoch_res = []
        res_pattern = re.compile(r'([0-9])*epoch results')
        for line in log_text_line:
            if res_pattern.search(line):
                all_epoch_res.append(line)

        ## format text line to pandas dataframe
        train_dataframe = format_dataframe(all_epoch_res)

        ## save csv files
        csv_file_path = deepcopy(file_path) 
        csv_file_path = re.sub(r'log', 'csv', csv_file_path)
        csv_file_path = re.sub(r'([\.a-zA-Z0-9\/]*)train([\.a-z]*)', r'\1train_log\2', csv_file_path)
        print(csv_file_path)
        #csv_dir_path = deepcopy(csv_file_path)
        #csv_dir_path = re.sub('([\.a-zA-Z0-9\/]*)_train_log.csv','',csv_dir_path)
        #print(csv_dir_path)
        train_dataframe.to_csv(csv_file_path, index=True)

        #break

    return None


if __name__ == "__main__":

    res = extract_loss(sys.argv[1])
