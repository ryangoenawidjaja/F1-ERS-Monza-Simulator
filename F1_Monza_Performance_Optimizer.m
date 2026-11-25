function F1_Monza_Performance_Optimizer

% F1 MONZA PERFORMANCE OPTIMIZER - educational thermodynamics laboratory
% 2026-inspired power/usable battery bounds, not complete FIA regulatory compliance.

fig=uifigure('Name','Monza | ERS Performance Optimizer','Position',[65 60 1370 830]);
root=uigridlayout(fig,[1 2]);root.ColumnWidth={340,'1x'};root.Padding=[12 12 12 12];
left=uipanel(root,'Title','MONZA PERFORMANCE CONTROLS');
g=uigridlayout(left,[21 1]);g.RowHeight={25,21,35,21,35,21,35,21,35,21,35,21,35,21,35,21,35,36,36,36,'1x'};g.Padding=[10 10 10 10];
uilabel(g,'Text','MONZA  •  5.793 km  •  illustrative model','FontWeight','bold');
uilabel(g,'Text','Deployment strategy');
strategy=uidropdown(g,'Items',{'Balanced','Aggressive','Conservative','Low-speed priority'},'Value','Balanced');
uilabel(g,'Text','Vehicle mass (kg)');mass=uislider(g,'Limits',[700 1000],'Value',800,'MajorTicks',[700 800 900 1000]);
uilabel(g,'Text','Wheel → battery efficiency');etaR=uislider(g,'Limits',[.4 .95],'Value',.75,'MajorTicks',[.4 .6 .75 .95]);
uilabel(g,'Text','Battery → wheel efficiency');etaD=uislider(g,'Limits',[.5 .98],'Value',.88,'MajorTicks',[.5 .7 .88 .98]);
uilabel(g,'Text','Initial battery energy (MJ)');initial=uislider(g,'Limits',[0 4],'Value',2,'MajorTicks',0:4);
uilabel(g,'Text','MGU-K electrical power limit (kW)');pmax=uislider(g,'Limits',[50 350],'Value',350,'MajorTicks',[50 150 250 350]);
uilabel(g,'Text','Required final battery reserve (MJ)');reserve=uislider(g,'Limits',[0 3],'Value',1,'MajorTicks',0:3);
uilabel(g,'Text','Engine mechanical power (kW, simplified)');engine=uislider(g,'Limits',[300 650],'Value',480,'MajorTicks',[300 400 500 650]);
run=uibutton(g,'Text','RUN / REFRESH','FontWeight','bold');compare=uibutton(g,'Text','COMPARE ALL STRATEGIES');reset=uibutton(g,'Text','RESET DEFAULTS');
notice=uitextarea(g,'Editable','off','Value',{'Model limitations:';'Speed limits are illustrative corner constraints.';'Engine power and drag are simplified.';'Lap time is an educational estimate.';'Not actual telemetry or FIA-compliant strategy.'},'FontSize',11);
right=uigridlayout(root,[4 2]);right.RowHeight={48,'1x','1x',110};right.ColumnWidth={'1x','1x'};
heading=uilabel(right,'Text','F1 ERS | MINIMIZE MONZA LAP TIME','FontWeight','bold','FontSize',20);heading.Layout.Column=[1 2];
a1=uiaxes(right);a2=uiaxes(right);a3=uiaxes(right);a4=uiaxes(right);
summary=uitextarea(right,'Editable','off','FontSize',12);summary.Layout.Column=[1 2];
run.ButtonPushedFcn=@(~,~)refresh(false);
compare.ButtonPushedFcn=@(~,~)refresh(true);
reset.ButtonPushedFcn=@(~,~)resetAll();
refresh(false);
    function p=parameters()
        p.mass=mass.Value;p.etaR=etaR.Value;p.etaD=etaD.Value;
        p.initial=initial.Value*1e6;p.reserve=reserve.Value*1e6;
        p.pmax=pmax.Value*1000;p.engine=engine.Value*1000;
    end
    function resetAll()
        strategy.Value='Balanced';mass.Value=800;etaR.Value=.75;etaD.Value=.88;
        initial.Value=2;pmax.Value=350;reserve.Value=1;engine.Value=480;refresh(false);
    end
    function refresh(allCases)
        p=parameters();names={'Conservative','Balanced','Aggressive','Low-speed priority'};
        base=lapModel(p,'Engine only');
        if allCases
            results=cell(1,4);
            for k=1:4,results{k}=lapModel(p,names{k});end
            times=cellfun(@(s)s.time,results);
            bar(a4,times);a4.XTick=1:4;a4.XTickLabel={'Conserv.','Balanced','Aggressive','Low-speed'};
            ylabel(a4,'Lap time (s)');title(a4,'Strategy comparison');grid(a4,'on');
            [~,best]=min(times);r=results{best};
            strategy.Value=names{best};
        else
            r=lapModel(p,strategy.Value);
            bar(a4,[r.brakeEnergy,r.harvest,r.deploy,r.losses]/1e6);
            a4.XTick=1:4;a4.XTickLabel={'Braking KE','Stored','Used','Losses'};
            ylabel(a4,'Energy (MJ)');title(a4,'Energy accounting (different boundaries)');grid(a4,'on');
        end
        plot(a1,base.x/1000,base.v*3.6,'--','Color',[.55 .55 .55]);hold(a1,'on');
        plot(a1,r.x/1000,r.v*3.6,'LineWidth',1.5,'Color',[.1 .5 .9]);hold(a1,'off');
        title(a1,'Vehicle speed');xlabel(a1,'Distance (km)');ylabel(a1,'km/h');legend(a1,{'Engine only','ERS active'},'Location','best');grid(a1,'on');
        stairs(a2,r.x(1:end-1)/1000,r.power/1000,'LineWidth',1.3,'Color',[.9 .4 .1]);
        yline(a2,0,'--');title(a2,'MGU-K electrical power (+ deploy / - charge)');
        xlabel(a2,'Distance (km)');ylabel(a2,'kW');grid(a2,'on');
        plot(a3,r.x/1000,r.battery/1e6,'Color',[.1 .6 .3],'LineWidth',1.6);
        yline(a3,p.reserve/1e6,'--','Required reserve');ylim(a3,[0 4.1]);
        title(a3,'Battery energy');xlabel(a3,'Distance (km)');ylabel(a3,'MJ');grid(a3,'on');
        if p.initial<p.reserve
            warningText='WARNING: starting battery is below required final reserve.';
        elseif r.battery(end)+1e-5<p.reserve
            warningText='WARNING: final battery reserve constraint was not achieved.';
        else
            warningText='Battery reserve constraint satisfied.';
        end
        summary.Value={sprintf('ERS lap: %.2f s  |  Engine-only: %.2f s  |  Simulated improvement: %.2f s',r.time,base.time,base.time-r.time),...
            sprintf('Recovered: %.3f MJ  |  Deployed: %.3f MJ  |  Final battery: %.3f MJ',r.harvest/1e6,r.deploy/1e6,r.battery(end)/1e6),...
            sprintf('Conversion losses: %.3f MJ  |  Battery balance error: %.3g J',r.losses/1e6,r.residual),...
            [warningText '  Lap time is an illustrative model estimate, not real F1 performance.']};
    end
end

function out=lapModel(p,mode)
% Fixed distance integration; each step advances vehicle energy and time.
% Corner-speed envelope and braking lookahead prevent impossible late braking.

L=5793;dx=5;x=(0:dx:L)';if x(end)~=L,x=[x;L];end
N=numel(x);d=diff(x);
% Approximate corner locations and apex speeds, NOT actual telemetry.

cornerX=[0 1080 2080 3050 4020 4920 5793];
cornerV=[85 24 38 43 48 48 85]; % m/s; first/last are rolling start
vCap=110*ones(N,1);
for c=2:numel(cornerX)-1
    vCap=min(vCap,cornerV(c)+.15*abs(x-cornerX(c)));
end
vCap(1)=85;vCap(end)=85;

% Assumed maximum braking deceleration: 5.5 g
brakeA = 5.5 * 9.81;  % 53.96 m/s^2

for i=N-1:-1:1
    vCap(i)=min(vCap(i),sqrt(vCap(i+1)^2+2*brakeA*d(i)));
end
v=zeros(N,1);v(1)=85;E=zeros(N,1);E(1)=min(4e6,max(0,p.initial));
P=zeros(N-1,1);time=0;harvest=0;deploy=0;losses=0;brakeEnergy=0;
% Regenerative braking budget here is an illustrative cap of 7 MJ per lap.
harvestCap=7e6;
for i=1:N-1
    ds=d(i);speed=max(v(i),5);
    drag=.5*1.2*1.15*speed^2;rolling=.015*p.mass*9.81;
    resist=(drag+rolling)*ds;
    % Local maximum feasible speed at next step (includes upcoming corner braking).
    limitNext=vCap(i+1);
    engineWork=min(p.engine/speed*ds, 9000*ds);
    % Simple driver strategy: fraction of max electrical power requested.
    switch mode
        case 'Engine only',fraction=0;
        case 'Aggressive',fraction=1;
        case 'Balanced',fraction=.65;
        case 'Conservative',fraction=.35;
        otherwise
            % Prioritize low-speed acceleration, where additional wheel work is valuable.
            fraction=max(.2,min(1,1.5-speed/90));
    end
    % Do not use energy below reserve, unless reserve was already infeasible.
    usable=max(0,E(i)-p.reserve);
    requested=min([fraction*p.pmax*ds/speed,usable, max(0,p.mass*(limitNext^2-speed^2)/2+resist-engineWork)/p.etaD]);
    used=max(0,requested);
    driveWork=used*p.etaD;
    vUnconstrained=sqrt(max(0,speed^2+2*(engineWork+driveWork-resist)/p.mass));
    v(i+1)=min(limitNext,vUnconstrained);
    % If the vehicle must brake, recover some of the wheel braking work.
    kineticChange=.5*p.mass*(v(i+1)^2-speed^2);
    wheelBrake=max(0,engineWork+driveWork-resist-kineticChange);
    % No positive engine drive during braking: reduce artificial brake waste.
    if wheelBrake>0
        engineWork=0;used=0;driveWork=0;
        vUnconstrained=sqrt(max(0,speed^2-2*resist/p.mass));
        v(i+1)=min(limitNext,vUnconstrained);
        kineticChange=.5*p.mass*(v(i+1)^2-speed^2);
        wheelBrake=max(0,-resist-kineticChange);
    end
    dt=2*ds/max(speed+v(i+1),1);
    gained=min([wheelBrake*p.etaR,p.pmax*dt,4e6-E(i),harvestCap-harvest]);
    gained=max(0,gained);
    E(i+1)=E(i)+gained-used;
    harvest=harvest+gained;deploy=deploy+used;
    brakeEnergy=brakeEnergy+wheelBrake;
    losses=losses+(gained/p.etaR-gained)+used*(1-p.etaD);
    P(i)=(used-gained)/dt;
    time=time+dt;
end
out=struct('x',x,'v',v,'battery',E,'power',P,'time',time,...
    'harvest',harvest,'deploy',deploy,'losses',losses,'brakeEnergy',brakeEnergy,...
    'residual',(E(end)-E(1))-(harvest-deploy));
end
