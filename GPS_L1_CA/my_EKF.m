function [x_est, P_est] = my_EKF(x_est, P_est, velocity, observations, satellite_positions, settings)
    % Extended Kalman Filter (EKF) for GNSS positioning
    %
    % Inputs:
    %   x_est: Current state estimate [position; velocity; clock bias]
    %   P_est: Current state covariance matrix
    %   velocity: Control input (velocity) [vx; vy; vz]
    %   observations: Pseudorange measurements from satellites
    %   satellite_positions: Positions of satellites in ECEF coordinates
    %   settings: Structure containing settings (e.g., navSolPeriod)
    %
    % Outputs:
    %   x_est: Updated state estimate
    %   P_est: Updated state covariance matrix

    % Validate inputs
    validateattributes(x_est, {'double'}, {'vector', 'numel', 7});
    validateattributes(P_est, {'double'}, {'size', [7, 7]});
    validateattributes(velocity, {'double'}, {'vector', 'numel', 3});
    validateattributes(observations, {'double'}, {'vector'});
    validateattributes(satellite_positions, {'double'}, {'2d'});
    validateattributes(settings, {'struct'}, {});

    % Define constants
    dt = settings.navSolPeriod / 1000;  % Convert milliseconds to seconds
    num_satellites = length(observations);  % Number of satellites
    satellite_positions = satellite_positions';  % Transpose for easier access

    % State transition matrix
    state_transition_matrix = [1, 0, 0, dt, 0, 0, 0;
                               0, 1, 0, 0, dt, 0, 0;
                               0, 0, 1, 0, 0, dt, 0;
                               0, 0, 0, 1, 0, 0, 0;
                               0, 0, 0, 0, 1, 0, 0;
                               0, 0, 0, 0, 0, 1, 0;
                               0, 0, 0, 0, 0, 0, 1];

    % Control input matrix
    control_input_matrix = [0, 0, 0;
                           0, 0, 0;
                           0, 0, 0;
                           dt, 0, 0;
                           0, dt, 0;
                           0, 0, dt;
                           0, 0, 0];

    % Process noise covariance matrix
    if (settings.dataNo == 0)       % Urban
        % 如果系统动态变化较快（如高速运动），可以增大 Q 的值。 如果系统动态变化较慢（如低速运动或静止），可以减小 Q 的值。
        process_noise_covariance = diag([1000, 1000, 1000, 1000, 1000, 1000, 1000]);
        % 如果测量噪声较大（如信号遮挡或多径效应），可以增大 R 的值。如果测量噪声较小（如开阔天空环境），可以减小 R 的值。
        measurement_noise_covariance = diag(ones(1, num_satellites) * 1000);
    else
        process_noise_covariance = diag([100, 100, 100, 10, 10, 10, 100]);
        measurement_noise_covariance = diag(ones(1, num_satellites) * 10);
    end

    % Measurement noise covariance matrix
    % measurement_noise_covariance = diag(ones(1, num_satellites) * 10);

    % EKF Prediction Step
    x_pred = state_transition_matrix * x_est + control_input_matrix * velocity;
    P_pred = state_transition_matrix * P_est * state_transition_matrix' + process_noise_covariance;

    % EKF Update Step
    for i = 1:num_satellites
        % Calculate predicted pseudorange
        satellite_position = satellite_positions(i, :)';
        position_difference = satellite_position - x_pred(1:3);
        predicted_pseudorange = norm(position_difference) + x_pred(7);

        % Measurement residual
        measurement_residual = observations(i) - predicted_pseudorange;

        % Jacobian of the measurement model
        jacobian = [-position_difference(1) / predicted_pseudorange, ...
                    -position_difference(2) / predicted_pseudorange, ...
                    -position_difference(3) / predicted_pseudorange, ...
                    0, 0, 0, 1];

        % Kalman gain
        innovation_covariance = jacobian * P_pred * jacobian' + measurement_noise_covariance(i, i);
        kalman_gain = P_pred * jacobian' / innovation_covariance;

        % Update state estimate
        x_pred = x_pred + kalman_gain * measurement_residual;

        % Update estimate covariance
        P_pred = (eye(7) - kalman_gain * jacobian) * P_pred;
    end

    % Updated state and covariance
    x_est = x_pred;
    P_est = P_pred;

    % Display updated state
    disp('Updated state:');
    disp(x_est);
end