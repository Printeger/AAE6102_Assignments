function plotNavigation(navSolutions, settings)
%Functions plots variations of coordinates over time and a 3D position
%plot. It plots receiver coordinates in UTM system or coordinate offsets if
%the true UTM receiver coordinates are provided.  
%
%plotNavigation(navSolutions, settings)
%
%   Inputs:
%       navSolutions    - Results from navigation solution function. It
%                       contains measured pseudoranges and receiver
%                       coordinates.
%       settings        - Receiver settings. The true receiver coordinates
%                       are contained in this structure.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
% 
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis
%--------------------------------------------------------------------------
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
%USA.
%--------------------------------------------------------------------------

% CVS record:
% $Id: plotNavigation.m,v 1.1.2.25 2006/08/09 17:20:11 dpl Exp $

%% Plot results in the necessary data exists ==============================
if (~isempty(navSolutions))

    %% If reference position is not provided, then set reference position
    %% to the average postion
    if isnan(settings.truePosition.E) || isnan(settings.truePosition.N) ...
                                      || isnan(settings.truePosition.U)

        %=== Compute mean values ========================================== 
        % Remove NaN-s or the output of the function MEAN will be NaN.
        refCoord.E = mean(navSolutions.E(~isnan(navSolutions.E)));
        refCoord.N = mean(navSolutions.N(~isnan(navSolutions.N)));
        refCoord.U = mean(navSolutions.U(~isnan(navSolutions.U)));

        %Also convert geodetic coordinates to deg:min:sec vector format
        meanLongitude = dms2mat(deg2dms(...
            mean(navSolutions.longitude(~isnan(navSolutions.longitude)))), -5);
        meanLatitude  = dms2mat(deg2dms(...
            mean(navSolutions.latitude(~isnan(navSolutions.latitude)))), -5);

        refPointLgText = ['Mean Position\newline  Lat: ', ...
                            num2str(meanLatitude(1)), '{\circ}', ...
                            num2str(meanLatitude(2)), '{\prime}', ...
                            num2str(meanLatitude(3)), '{\prime}{\prime}', ...
                         '\newline Lng: ', ...
                            num2str(meanLongitude(1)), '{\circ}', ...
                            num2str(meanLongitude(2)), '{\prime}', ...
                            num2str(meanLongitude(3)), '{\prime}{\prime}', ...
                         '\newline Hgt: ', ...
                            num2str(mean(navSolutions.height(~isnan(navSolutions.height))), '%+6.1f')];
    else
        refPointLgText = 'Reference Position';
        refCoord.E = settings.truePosition.E;
        refCoord.N = settings.truePosition.N;
        refCoord.U = settings.truePosition.U;        
    end    
     
    figureNumber = 300;
    % The 300 is chosen for more convenient handling of the open
    % figure windows, when many figures are closed and reopened. Figures
    % drawn or opened by the user, will not be "overwritten" by this
    % function if the auto numbering is not used.
 
    %=== Select (or create) and clear the figure ==========================
    figure(figureNumber);
    clf   (figureNumber);
    set   (figureNumber, 'Name', 'Navigation solutions');
 
    %--- Draw axes --------------------------------------------------------
    handles(1, 1) = subplot(4, 2, 1 : 4);
    handles(3, 1) = subplot(4, 2, [5, 7]);
    handles(3, 2) = subplot(4, 2, [6, 8]);    
 
%% Plot all figures =======================================================
    % 定义新配色方案
    colorPalette = struct(...
        'E', [0, 0.4470, 0.7410],...    % 蓝色
        'N', [0.4660, 0.6740, 0.1880],... % 绿色
        'U', [0.8500, 0.3250, 0.0980],... % 橙色
        'scatter', [0.3010, 0.7450, 0.9330],... % 浅蓝
        'refPoint', [0.6350, 0.0780, 0.1840]... % 红色
    );

    %--- Coordinate differences in UTM system -----------------------------
    plot(handles(1, 1), ...
        [(navSolutions.E - refCoord.E)', ...
         (navSolutions.N - refCoord.N)',...
         (navSolutions.U - refCoord.U)'], ...
        'LineWidth', 1.5);
    
    % 设置颜色和样式
    lines = findobj(handles(1,1), 'Type', 'Line');
    set(lines(1), 'Color', colorPalette.E);
    set(lines(2), 'Color', colorPalette.N, 'LineStyle', '--');
    set(lines(3), 'Color', colorPalette.U, 'LineStyle', '-.');

    title (handles(1, 1), 'Coordinates variations in UTM system', 'FontSize', 11);
    legend(handles(1, 1), 'E', 'N', 'U', 'Location', 'best');
    xlabel(handles(1, 1), ['Measurement period: ', num2str(settings.navSolPeriod), 'ms'], 'FontSize', 9);
    ylabel(handles(1, 1), 'Variations (m)', 'FontSize', 9);
    grid(handles(1, 1), 'on');
    set(handles(1,1), 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1);
    axis(handles(1, 1), 'tight');

    %--- Position plot in UTM system --------------------------------------
    scatter3(handles(3, 1), ...
        navSolutions.E - refCoord.E, ...
        navSolutions.N - refCoord.N, ...
        navSolutions.U - refCoord.U, ...
        40, colorPalette.scatter, 'filled', 'MarkerEdgeColor', 'k');
    
    hold(handles(3, 1), 'on');
    % 绘制参考点
    plot3(handles(3, 1), 0, 0, 0, ...
        'r+', 'LineWidth', 2, 'MarkerSize', 15, 'Color', colorPalette.refPoint);
    hold(handles(3, 1), 'off');
    
    view(handles(3, 1), 25, 60); % 调整视角
    axis(handles(3, 1), 'equal');
    grid(handles(3, 1), 'on');
    set(handles(3,1), 'GridAlpha', 0.4, 'MinorGridAlpha', 0.2);
    
    legend(handles(3, 1), 'Measurements', refPointLgText, 'Location', 'northeast');
    title(handles(3, 1), 'Positions in UTM system (3D plot)', 'FontSize', 11);
    xlabel(handles(3, 1), 'East (m)', 'FontSize', 9);
    ylabel(handles(3, 1), 'North (m)', 'FontSize', 9);
    zlabel(handles(3, 1), 'Upping (m)', 'FontSize', 9);

    %--- 设置图形整体样式 ------------------------------------------------
    set(figureNumber, 'Color', 'w'); % 白色背景
    set(findall(figureNumber, 'Type', 'axes'), 'FontSize', 9, 'Box', 'off');
    set(findall(figureNumber, 'Type', 'text'), 'FontSize', 9);
    set(figureNumber, 'Position', [100 100 800 600]); % 统一尺寸

    %--- Satellite sky plot -----------------------------------------------
    skyPlot(handles(3, 2), ...
            navSolutions.az, ...
            navSolutions.el, ...
            navSolutions.PRN(:, 1));
        
    title (handles(3, 2), ['Sky plot (mean PDOP: ', ...
                               num2str(mean(navSolutions.DOP(2,:))), ')']);  
                           
else
    disp('plotNavigation: No navigation data to plot.');
end % if (~isempty(navSolutions))







%% for ekf --sbs

%% Plot results in the necessary data exists ==============================
if (~isempty(navSolutions))

    %% If reference position is not provided, then set reference position
    %% to the average postion
    if isnan(settings.truePosition.E) || isnan(settings.truePosition.N) ...
                                      || isnan(settings.truePosition.U)

        %=== Compute mean values ========================================== 
        % Remove NaN-s or the output of the function MEAN will be NaN.
        % refCoord.E = navSolutions.E_kf(end);  % change ref point to the last one
        % refCoord.N = navSolutions.N_kf(end);
        % refCoord.U = navSolutions.U_kf(end);
        refCoord.E = mean(navSolutions.E_kf(~isnan(navSolutions.E_kf)));
        refCoord.N = mean(navSolutions.N_kf(~isnan(navSolutions.N_kf)));
        refCoord.U = mean(navSolutions.U_kf(~isnan(navSolutions.U_kf)));

        %Also convert geodetic coordinates to deg:min:sec vector format
        meanLongitude = dms2mat(deg2dms(...
            mean(navSolutions.longitude_kf(~isnan(navSolutions.longitude_kf)))), -5);
        meanLatitude  = dms2mat(deg2dms(...
            mean(navSolutions.latitude_kf(~isnan(navSolutions.latitude_kf)))), -5);

        refPointLgText = ['Mean Position\newline  Lat: ', ...
                            num2str(meanLatitude(1)), '{\circ}', ...
                            num2str(meanLatitude(2)), '{\prime}', ...
                            num2str(meanLatitude(3)), '{\prime}{\prime}', ...
                         '\newline Lng: ', ...
                            num2str(meanLongitude(1)), '{\circ}', ...
                            num2str(meanLongitude(2)), '{\prime}', ...
                            num2str(meanLongitude(3)), '{\prime}{\prime}', ...
                         '\newline Hgt: ', ...
                            num2str(mean(navSolutions.height_kf(~isnan(navSolutions.height_kf))), '%+6.1f')];
    else
        refPointLgText = 'Reference Position';
        refCoord.E = settings.truePosition.E;
        refCoord.N = settings.truePosition.N;
        refCoord.U = settings.truePosition.U;        
    end    
     
    figureNumber = 600;
    % The 300 is chosen for more convenient handling of the open
    % figure windows, when many figures are closed and reopened. Figures
    % drawn or opened by the user, will not be "overwritten" by this
    % function if the auto numbering is not used.
 
    %=== Select (or create) and clear the figure ==========================
    figure(figureNumber);
    clf   (figureNumber);
    set   (figureNumber, 'Name', 'EKF Navigation solutions');
 
    %--- Draw axes --------------------------------------------------------
    handles(1, 1) = subplot(4, 2, 1 : 4);
    handles(3, 1) = subplot(4, 2, [5, 7]);
    handles(3, 2) = subplot(4, 2, [6, 8]);    
 
%% Plot all figures =======================================================
    % 使用统一配色方案
    colorPalette = struct(...
        'E', [0, 0.4470, 0.7410],...    % 蓝色
        'N', [0.4660, 0.6740, 0.1880],... % 绿色
        'U', [0.8500, 0.3250, 0.0980],... % 橙色
        'scatter', [0.3010, 0.7450, 0.9330],... % 浅蓝
        'refPoint', [0.6350, 0.0780, 0.1840]... % 红色
    );

    %--- Coordinate differences in UTM system -----------------------------
    plot(handles(1, 1), ...
        [(navSolutions.E_kf - refCoord.E)', ...
         (navSolutions.N_kf - refCoord.N)',...
         (navSolutions.U_kf - refCoord.U)'], ...
        'LineWidth', 1.5);
    
    % 设置颜色和样式
    lines = findobj(handles(1,1), 'Type', 'Line');
    set(lines(1), 'Color', colorPalette.E);
    set(lines(2), 'Color', colorPalette.N, 'LineStyle', '--');
    set(lines(3), 'Color', colorPalette.U, 'LineStyle', '-.');

    title (handles(1, 1), 'EKF Coordinates variations in UTM system', 'FontSize', 11);
    legend(handles(1, 1), 'E', 'N', 'U', 'Location', 'best');
    xlabel(handles(1, 1), ['Measurement period: ', num2str(settings.navSolPeriod), 'ms'], 'FontSize', 9);
    ylabel(handles(1, 1), 'Variations (m)', 'FontSize', 9);
    grid(handles(1, 1), 'on');
    set(handles(1,1), 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1);
    axis(handles(1, 1), 'tight');

    %--- Position plot in UTM system --------------------------------------
    scatter3(handles(3, 1), ...
        navSolutions.E_kf - refCoord.E, ...
        navSolutions.N_kf - refCoord.N, ...
        navSolutions.U_kf - refCoord.U, ...
        40, colorPalette.scatter, 'filled', 'MarkerEdgeColor', 'k');
    
    hold(handles(3, 1), 'on');
    % 绘制参考点
    plot3(handles(3, 1), 0, 0, 0, ...
        'r+', 'LineWidth', 2, 'MarkerSize', 15, 'Color', colorPalette.refPoint);
    hold(handles(3, 1), 'off');
    
    legend(handles(3, 1), 'Measurements', refPointLgText);
 
    title (handles(3, 1), 'Positions in UTM system (3D plot)');
    xlabel(handles(3, 1), 'East (m)');
    ylabel(handles(3, 1), 'North (m)');
    zlabel(handles(3, 1), 'Upping (m)');
    
    %--- Satellite sky plot -----------------------------------------------
    skyPlot(handles(3, 2), ...
            navSolutions.az, ...
            navSolutions.el, ...
            navSolutions.PRN(:, 1));
        
    title (handles(3, 2), ['Sky plot (mean PDOP: ', ...
                               num2str(mean(navSolutions.DOP(2,:))), ')']);  
                           
else
    disp('plotNavigation: No navigation data to plot.');
end % if (~isempty(navSolutions))

%% 新增独立速度图表 ======================================================
if isfield(navSolutions, 'VX_kf') && isfield(navSolutions, 'VY_kf') && isfield(navSolutions, 'VZ_kf')
    velocityFigureNumber = 601;
    figure(velocityFigureNumber);
    clf(velocityFigureNumber);
    set(velocityFigureNumber, 'Name', 'EKF Velocity Components', 'Color', 'w');
    
    % 扩展配色方案
    velocityPalette = struct(...
        'VX', [0.4940, 0.1840, 0.5560],... % 紫色
        'VY', [0.9290, 0.6940, 0.1250],... % 黄色
        'VZ', [0.3010, 0.7450, 0.9330]...  % 浅蓝
    );
    
    % 创建子图布局
    ax1 = subplot(3,1,1);
    ax2 = subplot(3,1,2);
    ax3 = subplot(3,1,3);
    
    % 绘制各速度分量
    plot(ax1, navSolutions.VX_kf, 'Color', velocityPalette.VX, 'LineWidth', 1.5);
    title(ax1, 'EKF Velocity - X Component');
    ylabel(ax1, 'Velocity (m/s)');
    grid(ax1, 'on');
    
    plot(ax2, navSolutions.VY_kf, 'Color', velocityPalette.VY, 'LineWidth', 1.5);
    title(ax2, 'EKF Velocity - Y Component');
    ylabel(ax2, 'Velocity (m/s)');
    grid(ax2, 'on');
    
    plot(ax3, navSolutions.VZ_kf, 'Color', velocityPalette.VZ, 'LineWidth', 1.5);
    title(ax3, 'EKF Velocity - Z Component');
    xlabel(ax3, ['Measurement period: ', num2str(settings.navSolPeriod), 'ms']);
    ylabel(ax3, 'Velocity (m/s)');
    grid(ax3, 'on');
    
    % 统一样式设置
    set([ax1, ax2, ax3], 'FontSize', 9, 'GridAlpha', 0.3, 'Box', 'off');
    set(velocityFigureNumber, 'Position', [100 100 800 800]);
    linkaxes([ax1, ax2, ax3], 'x');
end
