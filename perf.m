% List of FRAMES_TO_ANALYZE to extract the skeletal data from
% Obtained from the beat tracking / onsets
postures = {[22,38,54,72,94,105,131,149,165,185,201,220,233,251,267,280],[36,51,67,79,97,114,128,140,156,167,182,194],[],[8,19,26,29,35,48,69,75,82,89,100],[17,26,33,41,47,57,67,73,84,90,97,105,112,125,131,139,150,157,165,172]};
NO_BONES = 17
% This contains the list of folders which have the dance data extracted in
% them
folders = {'natta_aakash','natta_abhishek','tatta_both','visharu_aakash','meddinatta'};

% Now reading the input, and calculating the matching
fid = fopen('postures_input.txt','r');
tline = fgetl(fid);
lines = 1
while ischar(tline)
    %disp(tline);
    parts = regexp(tline,', ','split');
    cls = parts{18};
    for i = 1:size(parts,2)-1
        part = parts(i);
        part = strrep(part,'(','');
        part = strrep(part,')','');
        % Now part contains data of the form '120.99,56.66', now let us
        % extract both the parts

        theta_parts = regexp(part,',','split');
        theta_y = str2double(theta_parts{1}(1));
        theta_xz = str2double(theta_parts{1}(2));
        % Now theta_y contains 120.99 and theta_z contains 56.66

        input{lines}{i}{1} = theta_y;
        input{lines}{i}{2} = theta_xz;
        input{lines}{i}{3} = str2num(cls);
    end
    tline = fgetl(fid);
    lines = lines + 1
end
fclose(fid);


fid = fopen('training_postures.txt','r');
tline = fgetl(fid);
lines = 1
while ischar(tline)
    parts = regexp(tline,', ','split');
    % Get the class label for the sample
    cls = parts{18};
    
    for i = 1:size(parts,2)-1
        part = parts(i);
        part = strrep(part,'(','');
        part = strrep(part,')','');
        % Now part contains data of the form '120.99,56.66', now let us
        % extract both the parts

        theta_parts = regexp(part,',','split');
        theta_y = str2double(theta_parts{1}(1));
        theta_xz = str2double(theta_parts{1}(2));
        % Now theta_y contains 120.99 and theta_z contains 56.66
       
        train{lines}{i}{1} = theta_y;
        train{lines}{i}{2} = theta_xz;
        train{lines}{i}{3} = str2num(cls);
    end
    tline = fgetl(fid);
    lines = lines + 1
end
fclose(fid);


outFileName = 'perf_output.txt'
fid = fopen(outFileName,'w');
% EXPONENTIAL METHOD
for i = 1:size(input,2)
    % Taking every test posture one by one, and finding its best class
    best_posture = -1;
    diff = 10000000000;
    best_class = -1;
    for j = 1:size(train,2)
        % Taking every reference posture one by one
        % Exponential matching

           sum_overall = 0;
           
           for bones = 1:NO_BONES
            sum_test_vi = 0;
            sum_train_vi = 0;
            % Converting the angles to radians, otherwise the value will be very
            % very large
            sum_test_vi = sum_test_vi + degtorad(abs(train{j}{bones}{1})) + degtorad(abs(train{j}{bones}{2}));
            sum_train_vi = sum_train_vi + degtorad(abs(input{i}{bones}{1})) + degtorad(abs(input{i}{bones}{2}));
            sum_overall = sum_overall + exp(abs(sum_test_vi - sum_train_vi));
            
           end
            
           if(sum_overall<diff)
            diff = sum_overall;
            best_posture = j;
            best_class = train{j}{bones}{3}
            %figure,imshow(strcat('G:\backup\',folders{folderCount},'\color_USB-VID_045E&PID_02BF-0000000000000000_',num2str(i),'.png'))
           end        
    end
    fprintf(fid,'%d %d\n',best_class,input{i}{NO_BONES}{3});
end

fclose(fid);
[status,cmdout] = system('python perf.py 14')
pause

% LINEAR METHOD
fid = fopen(outFileName,'w');

for i = 1:size(input,2)
    % Taking every test posture one by one, and finding its best class
    best_posture = -1;
    diff = 10000000000;
    best_class = -1;
    sum_test = 0;
    for bones = 1:NO_BONES
        sum_test = sum_test + abs(input{i}{bones}{1}) + abs(input{i}{bones}{2});
    end
    for j = 1:size(train,2)
       sum_train = 0;
       for bones = 1:NO_BONES
        sum_train = sum_train + abs( train{j}{bones}{1}) + abs( train{j}{bones}{2});
       end
       if(abs(sum_test - sum_train)<diff)
        diff = abs(sum_test - sum_train);
        best_posture = j;
        best_class = train{j}{bones}{3};
       end
    end
    fprintf(fid,'%d %d\n',best_class,input{i}{NO_BONES}{3});
end

fclose(fid);
[status,cmdout] = system('python perf.py 14')

pause

% WEIGHTED METHOD
fid = fopen(outFileName,'w');
give_weights_to_list= [5,6,9,10,13,14,17,18];


for i = 1:size(input,2)
    sum_test = 0;
    best_posture = -1;
    weight = 100;
    best_class = -1;
    diff = 10000000000;
    for bones = 1:NO_BONES
        if ismember(bones,give_weights_to_list)==1
            sum_test = sum_test + weight * (abs(input{i}{bones}{1}) + abs(input{i}{bones}{2}));
        else
            sum_test = sum_test + abs(input{i}{bones}{1}) + abs(input{i}{bones}{2});
        end    
    end
    for j = 1:size(train,2)
           sum_train = 0;
           for bones = 1:NO_BONES
               if ismember(bones,give_weights_to_list)==1
                    sum_train = sum_train + weight * (abs( train{j}{bones}{1}) + abs( train{j}{bones}{2}));
               else
                    sum_train = sum_train + abs( train{j}{bones}{1}) + abs( train{j}{bones}{2});
               end
           end
           if(abs(sum_test - sum_train)<diff)
            diff = abs(sum_test - sum_train);
            best_posture = j;
            best_class = train{j}{bones}{3};
           end
    end
    fprintf(fid,'%d %d\n',best_class,input{i}{NO_BONES}{3});
end
fclose(fid);
[status,cmdout] = system('python perf.py 14')