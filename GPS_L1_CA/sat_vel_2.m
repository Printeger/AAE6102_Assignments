% calculate receiver velocity with raw doppler
% by. YMD 2025/03/10

wavelength = 2.99792458e8/1.57542e9;
sat_poss=navSolutions.satllitePosition;
sat_velo=navSolutions.satllitevelocity;

rec_poss=[navSolutions.X;navSolutions.Y;navSolutions.Z];
rec_velini=zeros(3,1);

pseudoranges=navSolutions.correctedP;
dt=round(navSolutions.transmitTime(1,2)-navSolutions.transmitTime(1,1));


% decide the time for doppler measurements
times_dp=[];dopplers=[];
for k=1:length(trackResults)
    if(trackResults(k).status=='T')
        time_dp=trackResults(k).absoluteSample/settings.samplingFreq;
        dopp=trackResults(k).carrFreq-settings.IF;
        times_dp=[times_dp;time_dp];
        dopplers=[dopplers;dopp];
    end
end

dopplers_avg=[];

for t=1:dt:length(sat_poss)
    doppler_avg=zeros(size(times_dp,1),1);
    for k=1:size(times_dp,1)
        % index=find(abs(times_dp(k,:)-t)<=0.001);
        index_p=find(abs(times_dp(k,:)-t+0.5)<=0.0005);
        index_l=find(abs(times_dp(k,:)-t-0.5)<=0.0005);
        doppler_avg(k)=mean(dopplers(k,index_p:index_l));
    end
    dopplers_avg=[dopplers_avg,doppler_avg];
end

est_vel=[];
for t=1:dt:length(sat_poss)

    sats_pos=sat_poss{t};
    rec_pos=rec_poss(:,t);

    % init matrix
    u=(repmat(rec_pos,1,5)-sats_pos)./repmat(pseudoranges(:,t),1,3)';
    B=[u',ones(size(u,2),1)];
    C=[];
    for i=1:size(times_dp,1)
        C0=u(:,i)'*sat_velo{t}(:,i)+wavelength*dopplers_avg(i,t);
        C=[C;C0];
    end
    x=(B'*B)\(B'*C);
    est_vel=[est_vel,x];
end