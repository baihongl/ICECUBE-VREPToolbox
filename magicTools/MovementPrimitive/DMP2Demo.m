%   DMP2Demo
%   Haopeng Hu
%   2019.03.11

%% Run an empty DMP

% dmp = DMP2(25,5,8,40);
% [Y,x,fx] = dmp.run(0,1,1);
% dmp.plot(x,Y,1);
% dmp.plotGaussian(x,fx,1);

%% Learn a minimal jerk trajectory

% load('Data\SimpleMinJerk.mat');
dmp = DMP2(25,5,8,10);
dmp = dmp.LWR(1,T);
[Y,x,fx] = dmp.run(T(1,1),T(end,1),1);
dmp.plot(x,Y,1);
dmp.plotGaussian(x,fx,1);
dmp.plotCompare(Y,T,1);