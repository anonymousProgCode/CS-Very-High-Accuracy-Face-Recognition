% keep the dataset in rootFolder
% Haar Transform based MM 
%% For AT&T dataset
% link for datasets are given in description
categories = {'s1','s2','s3','s4','s5','s6','s7','s8','s9','s10',...
    's11','s12','s13','s14','s15','s16','s17','s18','s19','s20',...
    's21','s22','s23','s24','s25','s26','s27','s28','s29','s30',...
    's31','s32','s33','s34','s35','s36','s37','s38','s39','s40'};

rootFolder = 'AT&T';

%% For Extended Yale B Uncropped
rootFolder = 'ExtendedYaleB';

categories = {'yaleB11','yaleB12', 'yaleB13', 'yaleB15','yaleB16',...
    'yaleB17','yaleB18', 'yaleB19', 'yaleB20','yaleB21', 'yaleB22', 'yaleB23',...
    'yaleB24','yaleB25','yaleB26','yaleB27', 'yaleB28', 'yaleB29','yaleB30',...
    'yaleB31','yaleB32', 'yaleB33', 'yaleB34', 'yaleB35','yaleB36',...
    'yaleB37','yaleB38', 'yaleB39'};


%% For GIT face datasets. This is the color dataset and hence need to convert to grey dataset
categories = {'s01','s02','s03','s04','s05','s06','s07','s08','s09','s10',...
    's11','s12','s13','s14','s15','s16','s17','s18','s19','s20',...
    's21','s22','s23','s24','s25','s26','s27','s28','s29','s30',...
    's31','s32','s33','s34','s35','s36','s37','s38','s39','s40',...
    's41','s42','s43','s44','s45','s46','s47','s48','s49','s50'};

rootFolder = 'GIT';

%% Read the dataset and store the images in an imagestore --- Shuffle the data and run the code 10 times and calculate average accuracy
imds = imageDatastore(fullfile(rootFolder, categories), 'LabelSource',...
    'foldernames');
%% Create training and test set by randomly selecting the samples from all groups and shuffle the sets
% two separate imagestores
[TrainFace TestFace] = splitEachLabel(imds,0.7,'randomized'); % 70% in training 30% in test set
%Shuffle
TrainFace = shuffle(TrainFace);
TestFace = shuffle(TestFace);
% labels
Y = TrainFace.Labels; % Labels for training set
Y1 = TestFace.Labels; % labels for test set

L = length(Y); % Number of samples in training set
L1 = length(Y1); % number of samples in test set

n = size(readimage(TrainFace,1),1)* size(readimage(TrainFace,1),2) % Total number of pixels in grey image
%% Further processing
nr = size(readimage(TrainFace,1),1); %Number of rows in image
nc = size(readimage(TrainFace,1),2); %Number of columns in image

Xs = zeros(L,nc); % matrix containing the compressed samples for training 
XsT = zeros(L1,nc); %matrix containing the compressed samples test

% matrix C contains the different number of samples selected in each run.
% The value of number of samples depends on the size of image because we
% need to select some fraction of it which in turn decides the sensing
% ratio M/N. M is no. of samples

%C = [2576 60 42]; suitable for AT&T dataset. Other
%intermeadiate values can also be explored.
%C = [3072 100 20] % for extended Yale and GIT dataset
%C = [3072 100 20 15]; for Extended yale cropped 

Accuracy = zeros(length(C),1); % accuracy corresponding to each number of samples

% Phi is haar transform based measurment matrix of size (M,N). Here c represents
% the M in each run.
h = generate_haar2(3000,2^15); ------------------------------------------------------Haar for AT&T
%h = generate_haar2(5000,2^19); -----------------------------------------------------Haar for EYB and GIT
for j=1:length(C)
    c = C(j);
    
    Phi = h(1:c,1:n); % haar transform based measurement matrix
    Xs = zeros(L,c);
    XsT = zeros(L1,c);

    for i=1:L
        img = readimage(TrainFace,i);
        if ndims(img)>2
            img = rgb2gray(img); % convert the images grey if not already
        end
        
        img = permute(img,[2,1]); % to stack images row-wise to mimic rolling shutter readout technique
        
        img = double(img(:));
        
        Xs(i,:) = Phi*img; % Perform the CS and the results are store in training set
    end
    Xs = zscore(Xs,1,2); % zscore of samples of each image are calculated.
    
    for i=1:L1
        img = readimage(TestFace,i);
        if ndims(img)>2
            img = rgb2gray(img); % convert the images grey if not already
        end
        img = permute(img,[2,1]);
        img = double(img(:));
        
        XsT(i,:) = Phi*img;
    end
    XsT = zscore(XsT,1,2);
    % SVM in CS
    t = templateSVM('KernelFunction','Linear');
    mdl = fitcecoc(Xs,Y,'Coding','onevsall','Learners',t); % train the model on training set
    preds = predict(mdl,XsT); % make predictions on test set
    acc = sum(preds==Y1)/L1 % accuracy for each of c
    Accuracy(j) = acc; % store accuracies in a matrix
end


