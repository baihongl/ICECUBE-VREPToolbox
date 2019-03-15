%HelloICECUBE_DMP
%   Haopeng Hu
%   2019.03.12

%   If you are new to ICECUBE, turn to HelloICECUBE_PickAndPlace.m please.

%   'magicTools\MovementPrimitive' is required.
%   Peter Corke's Robotics Toolbox is required.
%   Open 'scenes\UR5DMP_Demo.ttt'

%   Please running the following codes step by step
%% Initialization

% % Initialize ICECUBE
% step = 0.001;
% TIMEOUT = 10000;
% icecube = ICECUBE(step,TIMEOUT);
% % Get UR5's handles
% icecube = icecube.getUR5Handles();
% 
% % Initialize the DMP (6 DoF)
% % dmp = repmat(DMP2(25,5,8,50),[6,1]);

%% Acquire the demo trajectory

% initConfig = [0, pi/8, pi/2-pi/8, 0, -pi/2, 0];
% icecube.start();
% 
% % Move to initial configuration
% ur5MoveToJointPosition(icecube,initConfig);
% pause(1);
% tempQuat = ur5GetIKTipQuaternion(icecube);
% 
% % Start the demo trajectory
% icecube = icecube.getObjectHandle('Toy2');
% targetPosition = icecube.getObjectPosition('Toy2') + [0,0,0.1];
% tempJoints = ur5MoveToConfigurationPro(icecube,targetPosition,tempQuat);
% pause(2);
% 
% % % Uncomment it if you are about to use jtraj for demo trajectory gen.
% % targetJoints = ur5GetJointPositions(icecube); 
% 
% % Stop and delete
% icecube.stop();
% icecube.delete();
% 
% clear ans icecube

%% Joint space interpolation (Peter Corke's 5th order polynomial)

% % Note that in Robotics Toolbox and ICECUBE all of the variables related to
% % physical meanings such as joint positions are covectors.
% 
% [T,dT,ddT] = jtraj(initConfig,targetJoints,1000);
% demoTraj_jtraj = cell(1,6);
% for i = 1:6
%     demoTraj_jtraj{i} = [T(:,i),dT(:,i),ddT(:,i)];
% end
% 
% % % Simulation (Not necessary)
% % icecube = ICECUBE(step,TIMEOUT);
% % icecube = icecube.getUR5Handles();
% % initConfig = [0, pi/8, pi/2-pi/8, 0, -pi/2, 0];
% % icecube.start();
% % % Move to initial configuration
% % ur5MoveToJointPosition(icecube,initConfig);
% % pause(1);
% % % Follow the demo trajectory (joint space)
% % for i = 1:size(T,1)
% %     ur5SetToJointPosition(icecube,T(i,:));
% % end
% % pause(2);
% % 
% % icecube.stop();
% % icecube.delete();
% % clear ans i icecube T dT ddT

%% Joint space interpolation (V-REP's RML method)

% demoTraj_rml = ur5JointTrajExtract(tempJoints,step);
% 
% % % Simulation (Not necessary)
% % T = tempJoints;
% % icecube = ICECUBE(step,TIMEOUT);
% % icecube = icecube.getUR5Handles();
% % initConfig = [0, pi/8, pi/2-pi/8, 0, -pi/2, 0];
% % icecube.start();
% % % Move to initial configuration
% % ur5MoveToJointPosition(icecube,initConfig);
% % pause(1);
% % % Follow the demo trajectory (joint space)
% % for i = 1:size(T,1)
% %     ur5SetToJointPosition(icecube,T(i,:));
% %     pause(icecube.step);
% % end
% % pause(2);
% % 
% % icecube.stop();
% % icecube.delete();
% % clear ans i icecube T

%% Learn the demo by 6 DMPs

% demoTraj2Learn = demoTraj_rml;
% dmpTraj = cell(1,6); x = cell(1,6); fx = cell(1,6);
% tau = 1;dt = step;
% for i = 1:6
%     dmp(i) = dmp(i).LWR(tau,demoTraj2Learn{i});
%     % Run it once for the next step to see the performance (Not necessary)
%     [dmpTraj{i},x{i},fx{i}] = dmp(i).run(demoTraj2Learn{i}(1,1),demoTraj2Learn{i}(end,1),tau,dt); 
% end
% clear i

%% Plot the learned trajectory (Wanna see the performance?)

% i = 6;
% dmp(i).plot(x{i},dmpTraj{i},tau);
% dmp(i).plotGaussian(x{i},fx{i},tau);
% % dmp(i).plotCompare(dmpTraj{i},demoTraj2Learn{i},tau);
% clear i

%% Reuse the dmp to drive the UR5 in V-REP scene (path follower)

% Now you can just rescale the duration tau to speed up or slow down it.
T = 10;
goal = targetJoints + [0,-0.1,0.1,0,0,0];

% Initialize ICECUBE
icecube = ICECUBE(step,TIMEOUT);
% Get UR5's handles
icecube = icecube.getUR5Handles();
icecube.start();

% Move the initial configuration
ur5MoveToJointPosition(icecube,initConfig);
pause(1);

% Run the DMPs to generate a 6-DoF trajectory
tempTraj = cell(1,6); tempX = cell(1,6); tempFx = cell(1,6);
for i = 1:6
    [tempTraj{i},tempX{i},tempFx{i}] = dmp(i).run(initConfig(i),goal(i),T);
end
% Transform to V-REP joint space trajectory
tempJointTraj = zeros(size(tempTraj{1},1),6);
for i = 1:6
    tempJointTraj(:,i) = tempTraj{i}(:,1);
end
% Run the robot to follow the path tempJointTraj
for i = 1:size(tempJointTraj,1)
    ur5SetToJointPosition(icecube,tempJointTraj(i,:));
end
pause(2);

icecube.stop();
icecube.delete();

% Plot
i = 1;
dmp(i).plot(tempX{i},tempTraj{i},T);
dmp(i).plotGaussian(tempX{i},tempFx{i},T)

clear ans icecube i

%% Notation
% % You can load 'Demo\Data\HelloICECUBE_DMP.mat'to quickly access to the
% % last step to see the usage of DMP,
% % in which
% % step, TIMEOUT: default properties of ICECUBE
% % tau,dt: duration and time step
% % dmpTraj, x, fx: trajectory generated by DMPs
% % demoTraj_jtraj: demo trajectory generated by jtraj