% clc;
% clear all;

clc;
clear all;

t1=clock;

LineWidth = 2;
h_con = sqrt(3);
tf = 100; % 仿真时长
N = 50;  % 粒子个数

%系统矩阵设置
% A = [0,1; -0.1,-0.2];      %系统矩阵
% B = [0; 1];                %
% C = [0.1,0.3];             %
I = eye(1,1);                %生成单位阵
%I(3,3) = 0;

%噪声
q = 0;                      %系统噪声均值
r = 0;                      %测量噪声均值
Q = 0.25;                   %系统噪声方差矩阵
R = 0.25;                   %测量噪声方差矩阵
W_noise = sqrt(Q)*randn(1,tf) + q;  %系统噪声
V_noise = sqrt(R)*randn(1,tf) + r;  %测量噪声
x = zeros(1,tf); % 系统状态真实值 初始值0
y = zeros(1,tf); % 系统状态真实值 初始值0
y(1,1) = x(1,1) + sqrt(R) * randn + r;

P = zeros(1,tf); % 采样方差
P(1,1) = 2;      % 初始采样分布的方差
xhatPart = zeros(1,tf);%状态估计值

xpart = zeros(N,tf);
for i = 1 : N
    xpart(i,1) = x(1,1) + sqrt(P(1,1)) * randn + q;%初始状态服从x=0均值，方差为sqrt(P)的高斯分布
end
% xArr = [x];
% yArr = [];
% xhatArr = [x];
% PArr = [P];
%xhatPartArr = [xhatPart]; %

%计算alpha阶次对应的GL定义系数 binomial coefficient
bino_fir = zeros(1,tf);       %微分阶次为0.7时GL定义下的系数
alpha = 1;
bino_fir(1,1) = 0.7;
for i = 2:1:tf
    bino_fir(1,i) = (1-(alpha+1)/(i-1))*bino_fir(1,i-1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% diff_X_real    表示k时刻状态的微分
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diff_X_real = 0;

for k = 2 : tf

    diff_X_real = 3*sin(2*x(1,k-1)) -x(1,k-1) + W_noise(1,k-1);
    rema = 0;
    for i = 2:1:k
        rema = rema + bino_fir(1,i)*x(1,k+1-i);
    end
    x(1,k) = diff_X_real - rema;
    %k时刻真实值
    y(1,k) = x(1,k) + V_noise(1,k);  %k时刻观测值

 %% 采样N个粒子
 for i = 1 : N
     %采样获得N个粒子
     xpartminus(i) = 3*sin(2*xpart(i,k-1)) - xpart(i,k-1) + sqrt(Q) * randn;
     temp = 0;
         for j = 2 : 1 : k
            temp = temp + bino_fir(1,j)*xpart(i,k+1-j);
         end
     xpartminus(i) = xpartminus(i) - temp;
     ypart = xpartminus(i);      %每个粒子对应观测值
     vhat = y(1,k) - ypart;             %与真实观测之间的似然
     q(i) = (1 / sqrt(R) / sqrt(2*pi)) * exp(-vhat^2 / 2 / R);
     %每个粒子的似然即相似度
 end

 %%
%权值归一化
qsum = sum(q);
for i = 1 : N
    q(i) = q(i) / qsum; %归一化后的权值 q
end

%%
 %根据权值重新采样
  for i = 1 : N 
      u = rand;
      qtempsum = 0; 
      for j = 1 : N
          qtempsum = qtempsum + q(j); 
          if qtempsum >= u 
              xpart(i,k) = xpartminus(j);
              break;
          else
              xpart(i,k) = xpart(i,k-1);
          end 
      end
  end
xhatPart(1,k) = mean(xpart(:,k));

%%
%最后的状态估计值即为N个粒子的平均值，这里经过重新采样后各个粒子的权值相同
% xArr = [xArr x];   
% yArr = [yArr y];  
% % xhatArr = [xhatArr xhat]; 
% PArr = [PArr P]; 
% xhatPartArr = [xhatPartArr xhatPart];

end

RMSE = 0;
for i = 1:1:tf
    RMSE = RMSE + (x(1,i) - xhatPart(1,i))^2;
end
RMSE = sqrt( RMSE/tf )

t2=clock;
FPF = etime(t2,t1)

%%
t = 1 : tf;
figure;
plot(t, x, 'b-.', t, xhatPart, 'k-');
legend('Real Value','Estimated Value');
set(gca,'FontSize',10); 
xlabel('time step'); 
ylabel('state');
title('Particle filter')
%xhatRMS = sqrt((norm(x - xhat))^2 / tf);
%xhatPartRMS = sqrt((norm(xArr - xhatPartArr))^2 / tf);
figure;
plot(t,(x-xhatPart).^2,'b');
title('The SE error of PF')

%%
% t = 0 : tf;
% figure;
% plot(t, xArr, 'b-.', t, xhatPartArr, 'k-');
% legend('Real Value','Estimated Value');
% set(gca,'FontSize',10); 
% xlabel('time step'); 
% ylabel('state');
% title('Particle filter')
% xhatRMS = sqrt((norm(xArr - xhatArr))^2 / tf);
% xhatPartRMS = sqrt((norm(xArr - xhatPartArr))^2 / tf);
% figure;
% plot(t,abs(xArr-xhatPartArr),'b');
% title('The error of PF')

