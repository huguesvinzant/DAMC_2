clear variables
close all
clc

%% loading data

load('Data.mat')

%% partitionning data

%Only 5% used for training, the rest used fot testing - Here we have to use 
%at least 10% for training otherwise we get an error 
%"Warning: X is rank deficient to within machine precision." when applying 
%the regress function. No PCA applied in this case 

n_samples = length(Data);

trainData = Data(1:ceil(0.1*n_samples),:);
trainPosX = PosX(1:ceil(0.1*n_samples));
trainPosY = PosY(1:ceil(0.1*n_samples));

testData = Data(ceil(0.1*n_samples)+1:end,:);
testPosX = PosX(ceil(0.1*n_samples)+1:end);
testPosY = PosY(ceil(0.1*n_samples)+1:end);

%% Linear regressor

I_train = ones(length(trainPosX),1);
I_test = ones(length(testPosX),1);
linear_trainData = [I_train trainData];
linear_testData = [I_test testData];

X_regressor_linear = regress(trainPosX, linear_trainData);
X_error_tr_lin = immse(trainPosX, linear_trainData*X_regressor_linear);
X_error_te_lin = immse(testPosX, linear_testData*X_regressor_linear);

Y_regressor_linear = regress(trainPosY, linear_trainData);
Y_error_tr_lin = immse(trainPosY, linear_trainData*Y_regressor_linear);
Y_error_te_lin = immse(testPosY, linear_testData*Y_regressor_linear);

figure(1)

subplot(2,2,1), plot(trainPosX), hold on, plot(linear_trainData*X_regressor_linear),
legend('PosX','Predicted PosX'), title('Train')
subplot(2,2,2), plot(testPosX), hold on, plot(linear_testData*X_regressor_linear),
legend('PosX','Predicted PosX'), title('Test')
subplot(2,2,3), plot(trainPosY), hold on, plot(linear_trainData*Y_regressor_linear),
legend('PosY','Predicted PosY'), title('Train')
subplot(2,2,4), plot(testPosY), hold on, plot(linear_testData*Y_regressor_linear),
legend('PosY','Predicted PosY'), title('Test')

%% LASSO

n_samples = length(Data);
lambda = logspace(-10, 0, 15);

%here we use 5% as requested
trainData = Data(1:ceil(0.05*n_samples),:);
trainPosX = PosX(1:ceil(0.05*n_samples));
trainPosY = PosY(1:ceil(0.05*n_samples));

testData = Data(ceil(0.05*n_samples)+1:end,:);
testPosX = PosX(ceil(0.05*n_samples)+1:end);
testPosY = PosY(ceil(0.05*n_samples)+1:end);

[B_X, STATS_X] = lasso(trainData, trainPosX, 'Lambda', lambda, 'CV', 10);
%Here logspace generates n points between decades 10^a and 10^b
%We cannot simply write "'CV', 10" in the function since we need to respect
%the chronological order. That is why we make our own cvpartition (however
%the CV will only take a partition created with CVPARTITION? Cannot get chronology
%from this function either..)

[B_Y, STATS_Y] = lasso(trainData, trainPosY, 'Lambda', lambda, 'CV', 10);

figure(1) % plot of the non-zero weights with lambda

subplot(1,2,1)
semilogx(lambda, STATS_X.DF);
title('Number of non-zero weights as a function of lambda for PosX');
xlabel('Lambda values');
ylabel('Number of non-zero weights');
hold on;

subplot(1,2,2)
semilogx(lambda, STATS_Y.DF);
title('Number of non-zero weights as a function of lambda for PosY');
xlabel('Lambda values');
ylabel('Number of non-zero weights');

figure(2) %plot of the MSE with lambda.

subplot(1,2,1)
semilogx(lambda, STATS_X.MSE);
title('Mean square error (MSE) as a function of lambda for PosX');
xlabel('Lambda values');
ylabel('MSE');
hold on;

subplot(1,2,2)
semilogx(lambda, STATS_Y.MSE);
title('Mean square error (MSE) as a function of lambda for PosY');
xlabel('Lambda values');
ylabel('MSE');

[min_MSE_X, ind_x] = min(STATS_X.MSE);
min_lambda_X = lambda(ind_x);
beta_X = B_X(:,ind_x);
intercept_X = STATS_X.Intercept(ind_x);

[min_MSE_Y, ind_y] = min(STATS_Y.MSE);
min_lambda_Y = lambda(ind_y);
beta_Y = B_Y(:,ind_y);
intercept_Y = STATS_Y.Intercept(ind_y);

%Regressing the data using the best beta and intercept (found using lambda)
X_reg = regress(testPosX, testData);
%Computing the corresponding error
X_error_te = immse(testPosX, testData*X_reg);

Y_reg = regress(testPosY, testData);
Y_error_te = immse(testPosY, testData*Y_reg);

figure(3)
subplot(1,2,1), plot(testPosX), hold on, plot(testData*X_reg),
legend('PosX','Predicted PosX'), title('PosX test set compared to its regressed version')
subplot(1,2,2), plot(testPosY), hold on, plot(testData*Y_reg),
legend('PosX','Predicted PosX'), title('PosY test set compared to its regressed version')


%% Elastic nets

alpha = 0.5;
lambda = logspace(-10, 0, 15);

[B_X_elastic, STATS_X_elastic] = lasso(trainData, trainPosX, 'Alpha', alpha, 'Lambda', lambda, 'CV', 10);

[B_Y_elastic, STATS_Y_elastic] = lasso(trainData, trainPosX, 'Alpha', alpha,'Lambda', lambda, 'CV', 10);

figure(4) % plot of the non-zero weights with alpha

%Comparison between elastic net and lasso
subplot(1,2,1)
semilogx(lambda, STATS_X_elastic.DF);
hold on
semilogx(lambda, STATS_X.DF);
legend('elastic', 'lasso');
title('Number of non-zero weights as a function of lambda for PosX');
xlabel('Lambda values');
ylabel('Number of non-zero weights');

subplot(1,2,2)
semilogx(lambda, STATS_Y_elastic.DF);
hold on;
semilogx(lambda, STATS_X.DF);
legend('elastic', 'lasso');
title('Number of non-zero weights as a function of lambda for PosY');
xlabel('Lambda values');
ylabel('Number of non-zero weights');

%For the lambda value corresponding to the best MSE, use the corresponding
%beta and intercept to regress the test data (PosX, PosY).

figure(5) %plot of the MSE with lambda.

subplot(1,2,1)
semilogx(lambda, STATS_X_elastic.MSE);
hold on;
semilogx(lambda, STATS_X.MSE);
title('Mean square error (MSE) as a function of lambda for PosX');
legend('elastic', 'lasso');
xlabel('Lambda values');
ylabel('MSE');
hold on;

subplot(1,2,2)
semilogx(lambda, STATS_Y_elastic.MSE);
hold on;
semilogx(lambda, STATS_Y.MSE);
title('Mean square error (MSE) as a function of lambda for PosY');
legend('elastic', 'lasso');
xlabel('Lambda values');
ylabel('MSE');

[min_MSE_X_elastic, ind_x_elastic] = min(STATS_X_elastic.MSE);
min_lambda_X_elastic = lambda(ind_x_elastic);
beta_X_elastic = B_X_elastic(:,ind_x_elastic);
intercept_X_elastic = STATS_X_elastic.Intercept(ind_x_elastic);

[min_MSE_Y_elastic, ind_y_elastic] = min(STATS_Y_elastic.MSE);
min_lambda_Y_elastic = lambda(ind_y_elastic);
beta_Y_elastic = B_Y_elastic(:,ind_y_elastic);
intercept_Y_elastic = STATS_Y_elastic.Intercept(ind_y_elastic);

%Regressing the data using the best beta and intercept (found using lambda)
X_reg_elastic = regress(testPosX, testData);
%Computing the corresponding error
X_error_te_elastic = immse(testPosX, testData*X_reg_elastic);

Y_reg_elastic = regress(testPosY, testData);
Y_error_te_elastic = immse(testPosY, testData*Y_reg_elastic);

%Plot
figure(6)
subplot(2,2,1), plot(testPosX), hold on, plot(testData*X_reg_elastic),
legend('PosX','Predicted PosX'), title('PosX test set compared to its elastic regressed version')
subplot(2,2,2), plot(testPosY), hold on, plot(testData*Y_reg_elastic),
legend('PosX','Predicted PosX'), title('PosY test set compared to its elastic regressed version')


subplot(2,2,3), plot(testPosX), hold on, plot(testData*X_reg),
legend('PosX','Predicted PosX'), title('PosX test set compared to its regressed version')
subplot(2,2,4), plot(testPosY), hold on, plot(testData*Y_reg),
legend('PosX','Predicted PosX'), title('PosY test set compared to its regressed version')

%% Cross validation for lambda and alpha

alphas = linspace(0,1,5);
lambda = logspace(-10, 0, 15);
i= 1;
for alpha = linspace(0.2,1,4)
    
    [B_X_elastic, STATS_X_elastic] = lasso(trainData, trainPosX, 'Alpha', alpha, 'Lambda', lambda, 'CV', 10);
    [B_Y_elastic, STATS_Y_elastic] = lasso(trainData, trainPosX, 'Alpha', alpha,'Lambda', lambda, 'CV', 10);
    
    %For the lambda value corresponding to the best MSE, use the corresponding
    %beta and intercept to regress the test data (PosX, PosY).

    [min_MSE_X_elastic, ind_x_elastic] = min(STATS_X_elastic.MSE);
    min_lambda_X_elastic(i) = lambda(ind_x_elastic);
    beta_X_elastic = B_X_elastic(:,ind_x_elastic);
    intercept_X_elastic = STATS_X_elastic.Intercept(ind_x_elastic);

    [min_MSE_Y_elastic, ind_y_elastic] = min(STATS_Y_elastic.MSE);
    min_lambda_Y_elastic(i) = lambda(ind_y_elastic);
    beta_Y_elastic = B_Y_elastic(:,ind_y_elastic);
    intercept_Y_elastic = STATS_Y_elastic.Intercept(ind_y_elastic);

    %Regressing the data using the best beta and intercept (found using lambda)
    X_reg_elastic = regress(testPosX, testData);
    Y_reg_elastic = regress(testPosY, testData);
    %Computing the corresponding error
    X_error_te_elastic(i) = immse(testPosX, testData*X_reg_elastic);
    Y_error_te_elastic(i) = immse(testPosY, testData*Y_reg_elastic);
    i=i+1
end

[min_X_error_te_elastic, ind_min_X_error] = min(X_error_te_elastic);
min_lambda_X = min_lambda_X_elastic(ind_min_X_error);
min_alpha_X = 0.2*ind_min_X_error;

[min_Y_error_te_elastic, ind_min_Y_error] = min(Y_error_te_elastic);
min_lambda_Y = min_lambda_Y_elastic(ind_min_Y_error);
min_alpha_Y = 0.2*ind_min_Y_error;