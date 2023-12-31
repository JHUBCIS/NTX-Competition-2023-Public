classdef ArmStateModel < handle
    % State controller for handling velocity control of an arm
    %
    % This controller contains all the logic and states for position and
    % velocity control of the arm.  This represents an internal state so
    % that when velocity commands are generated, they are applied to an
    % internal model of the arm and then absolute joint angles are
    % typically streamed to an output (MPL, vMPL, MiniV, etc).
    %
    % Internal timing is handled by calculating the difference between when
    % subsequent update commands are issued.
    %
    % Revisions:
    % 26JUN2014 Armiger: Added accel rules and min velocity limits
    % 10DEC2015 Armiger: Added roc ids for every joint
    
    % Notes:
    %
    % There are a variety of control scenarios that this class should
    % eventually include.  
    %
    % The baseline is joint based velocity control.
    % In this case the 7 upper arm joints are treated seperately and each
    % maintains its own position / velocity control status.  
    %
    % The hand is usually controled via a single state that has information
    % related to the roc ID and the current position, which is just a
    % normalized valie on 0-1
    %
    % Individual finger control can be either handled by ROC tables, which
    % has the limitation of being mutually exclusive.  OR individual
    % fingers would need their own account of position and hence their own
    % state
    %
    % We also may want a scenario in which some joints are mapped to
    % differing ROC tables. E.g. if there is a whole arm ROC mapped to
    % motion and another mapped to hand grasp
    %
    % Endpoint control is needed in a manner such that some joints are
    % mapped to Endopint command states while maintaining hand grasps via
    % ROC tables.  Both endpont position and velocity modes are desired
    %
    % 
    
    properties

        ApplyValueLimits = 1;
        ApplyVelocityLimits = 1;
        ApplyAccelerationLimits = 0;
        ApplyReturnToHome = 0;       % Used for 'simple' or 'complex' arm mode

        GLOBAL_GAIN_SCALE = 0.6;
        
        structState
        lastTime
        velocity = zeros(1,8);
        
        JointState;  % new array to store state of every joint
        
        RocStateId = 8; % not to be confused with RocId/RocValue
    end
    methods
        function obj = ArmStateModel
            % Create state for upper arm joints and roc grasps
            obj.lastTime = tic;
            
            % Get joint names from enumeration
            % Use this as a based string to then get xml defaults from user
            % config file
            jointNames = fieldnames(MPL.EnumArm);
            numJoints = length(jointNames);
            obj.JointState = repmat(obj.defaultState,numJoints,1); 
            
            for i = 1:numJoints
                r = UserConfig.getUserConfigVar(strcat(jointNames{i},'_LIMITS'),[0 30]);
                obj.JointState(i).Name = jointNames{i};
                obj.JointState(i).Min = r(1) * pi / 180;
                obj.JointState(i).Max = r(2) * pi / 180;
            end
%             r = UserConfig.getUserConfigVar('WRIST_FE_LIMITS',[-90 90]);
%             obj.structState(7).Name = 'Wrist FE';
%             
%             obj.structState(7).IsReversed = UserConfig.getUserConfigVar('WRIST_FE_DIRECTION',1);
%             obj.structState(7).MaxVelocity = 4;

            % Done with the new version of joint specific ROCs
            
            obj.structState = repmat(obj.defaultState,8,1);
            
            r = UserConfig.getUserConfigVar('SHOULDER_FE_LIMITS',[-35 170]);
            obj.structState(1).Name = 'Shoulder FE';
            obj.structState(1).Min = r(1) * pi / 180;
            obj.structState(1).Max = r(2) * pi / 180;

            r = UserConfig.getUserConfigVar('SHOULDER_AB_AD_LIMITS',[-110 15]);
            obj.structState(2).Name = 'Shoulder AA';
            obj.structState(2).Min = r(1) * pi / 180;
            obj.structState(2).Max = r(2) * pi / 180;

            r = UserConfig.getUserConfigVar('HUMERAL_ROT_LIMITS',[-90 90]);
            obj.structState(3).Name = 'Shoulder ROT';
            obj.structState(3).Min = r(1) * pi / 180;
            obj.structState(3).Max = r(2) * pi / 180;

            % Limit of ~120 degrees needed for TH Socket
            r = UserConfig.getUserConfigVar('ELBOW_LIMITS',[0 135]);
            obj.structState(4).Name = 'Elbow';
            obj.structState(4).MaxVelocity = 2;
            obj.structState(4).DefaultValue = 90 * pi / 180;
            obj.structState(4).Min = r(1) * pi / 180;
            obj.structState(4).Max = r(2) * pi / 180;

            r = UserConfig.getUserConfigVar('WRIST_ROT_LIMITS',[-90 90]);
            obj.structState(5).Name = 'Wrist ROT';
            obj.structState(5).IsReversed = 0;
            obj.structState(5).MaxVelocity = 4;
            obj.structState(5).Min = r(1) * pi / 180;
            obj.structState(5).Max = r(2) * pi / 180;

            r = UserConfig.getUserConfigVar('WRIST_AB_AD_LIMITS',[-35 35]);
            obj.structState(6).Name = 'Wrist DEV';
            obj.structState(6).Min = r(1) * pi / 180;
            obj.structState(6).Max = r(2) * pi / 180;

            r = UserConfig.getUserConfigVar('WRIST_FE_LIMITS',[-90 90]);
            obj.structState(7).Name = 'Wrist FE';
            
            IsReversed = isequal(-1,UserConfig.getUserConfigVar('WRIST_FE_DIRECTION',1));            
            obj.structState(7).IsReversed = IsReversed;
            obj.structState(7).MaxVelocity = 4;
            obj.structState(7).Min = r(1) * pi / 180;
            obj.structState(7).Max = r(2) * pi / 180;
            
            obj.structState(8).Name = 'Roc Hand';
            obj.structState(8).Min = 0;
            obj.structState(8).Max = 1;
            obj.structState(8).State = Controls.GraspTypes.Relaxed;
            obj.structState(8).MaxAcceleration = 1;
            obj.structState(8).DefaultValue = 0.15;

            loadTempState(obj);
            
        end
        function setRocId(obj,id)
            % Set the ROC ID
            obj.structState(obj.RocStateId).State = id;
        end
        function id = getRocId(obj)
            % Get the ROC ID
            id = obj.structState(obj.RocStateId).State;
        end
        function val = getRocVal(obj)
            % Get the current position in the ROC ID
            val = obj.structState(obj.RocStateId).Value;
        end
        function setVelocity(obj,id,velocity)
            obj.velocity(id) = velocity;
        end
        function value = getValues(obj)
            % Use this method rather than accessing the struct state
            % directly to perform joint direction correction
            v = [obj.structState(:).Value];
            isReversed = [obj.structState(:).IsReversed] ~= 0;
            v(isReversed) = -v(isReversed);
            value = v;
        end
        function setAllValues(obj,values)
            % set the state for manual positioning
            storedValues = [obj.structState(:).Value];
            assert(isequal(size(values(:)),size(storedValues(:))),...
                'Error input values must match stored value size');
            
            for i = 1:length(values)
                obj.structState(i).Value = values(i);
            end
        end
        function setValue(obj,id,value)
            % set the state for manual positioning of a single value

            % e.g. obj.setValue(obj.RocStateId,1)  % close hand
            obj.structState(id).Value = value;
        end
        function saveTempState(obj)
            % Save the state structure for use when restarting limb between
            % sessions
            
            tempFileName = 'lastArmState';
            fprintf('[%s] Saving joint state to: %s\n',mfilename,tempFileName);
            
            UiTools.save_temp_file(tempFileName,obj.structState);
            
        end
        function success = loadTempState(obj)
            % Load the state structure for use when restarting limb between
            % sessions
            success = true;
            tempFileName = 'lastArmState';
            fprintf('[%s] Loading joint angles from %s\n',mfilename,tempFileName);
            s = UiTools.load_temp_file(tempFileName);
            
            if isempty(s)
                success = false;
                return
            end

            % Validate the loaded file against the known state fields
            testState = Controls.ArmStateModel.defaultState;
            f = fieldnames(testState);
            for i = 1:length(f)
                if ~isfield(s,f{i})
                    warning('Expected field "%s" in temp state file %s. Aborting\n',f{i},tempFileName);
                    success = false;
                end
            end
            
            if ~success
                return
            else
                % 9/21/2016 RSA Update: Only update the Value, otherwise
                % the joint limits and other parameters will always be
                % reset
                for i = 1:length([s.Value])
                    obj.structState(i).Value = s(i).Value;
                end
                success = true;
            end
            
        end
        function upperArmValues = getUpperArmValues(obj)
            % Be sure to access Values using get method so reverse sign is
            % corrected
            v = obj.getValues();
            upperArmValues = v(1:7);
        end
        function [rocId, rocValue] = getRocValues(obj)
            %[rocId, rocValue] = getRocValues(obj)
            % Get the Roc Id maintained as the state of the joint defined
            % for holding Roc grasps
            v = obj.getValues();
            rocValue = v(obj.RocStateId);
            rocId = obj.structState(obj.RocStateId).State;
        end
        function update(obj)
            % perform the forward integration based on the elapsed time
            % apply rate limits
            % apply range limits
            
            dt = max(toc(obj.lastTime),0.001);

            
            for i = 1:length(obj.JointState)
                s = obj.JointState(i);
                
                % process roc state
                if ~isempty(s.RocId)
                    % Integrate velocity to get position
                    s.RocValue = s.RocValue + (s.RocVelocity*dt);
                    s.RocValue = max(min(s.RocValue,1),0);
                end
                obj.JointState(i) = s;
            end
            
            % Debug
            %obj.structState(5)
            
            % set the velocity state and copy the old velocity to last
            for i = 1:length(obj.structState)
                s = obj.structState(i);
                
                % Note: no limits on how fast this changes.  This is what
                % is input from the user using the setVelocity method
                v = obj.velocity(i);
                
                s.DesiredVelocity = v;
                
                % check return to home parameter.  If it is set then a null
                % command will result in an automatic return to the default
                % position.
                if obj.ApplyReturnToHome && s.DesiredVelocity == 0
                    
                    % Compute position error relative to default position
                    errorValue = s.Value - s.DefaultValue;
                    
                    % Define threshold for 'close to default value'.
                    % Within this threshold the velocity is computed based
                    % on the error in order to return perfectly to 0 error.
                    positionThreshold = 0.05;
                    if abs(errorValue) < positionThreshold
                        vReturn = abs(errorValue)/dt;
                    else
                        vReturn = s.DefaultVelocity;
                    end
                    
                    % command the state model in the direction of the
                    % default position at the default velocity
                    if errorValue < 0
                        s.DesiredVelocity = +vReturn;
                    else
                        s.DesiredVelocity = -vReturn;
                    end
                end
                
                
                
                if obj.ApplyAccelerationLimits && s.IsAccelLimited
                    desiredAccel = (s.DesiredVelocity - s.LastVelocity) ./ dt;
                    
                    % Enable 'stop fast rule'
                    % You should always be able to decelerate if moving
                    % in the intended direction.  Same also applys for if
                    % zero velocity case
                    if abs(s.DesiredVelocity) > 0
                        allowedAccel = sign(desiredAccel) * min(abs(desiredAccel),s.MaxAcceleration);
                    else
                        allowedAccel = desiredAccel;
                    end
                                        
                    % Integrate acceleration to get velocity
                    newV = s.LastVelocity + (allowedAccel*dt);
                    
                    % if the new velocity is non-zero, make sure it's not
                    % infinitesimal
                    if newV < 0
                        newV = min(newV,-0.1);
                    elseif newV > 0
                        newV = max(newV,+0.1);
                    end
                    
                else
                    % Use commanded velocity
                    newV = s.DesiredVelocity;
                end

                % Apply max velocity limits
                if obj.ApplyVelocityLimits
                    newV = sign(newV) * min(abs(newV),s.MaxVelocity);
                end

                s.LastVelocity = s.Velocity;
                s.Velocity = newV * obj.GLOBAL_GAIN_SCALE;
                
                % Integrate velocity to get position
                s.Value = s.Value + (s.Velocity*dt);
                
                % s.DesiredValue = s.DesiredValue + (s.DesiredVelocity*dt);
                s.DesiredValue = s.Value + (s.DesiredVelocity*dt);
                
                % Apply range limits
                if obj.ApplyValueLimits
                    s.Value = min(s.Value,s.Max);
                    s.Value = max(s.Value,s.Min);
                end
                
                obj.structState(i) = s;
                
            end
            
            obj.lastTime = tic;
            
        end
        function test(obj)
            
            h = GUIs.widgetStripChart();
            h.initialize(4,300,{'actual' 'desired' 'v' 'vdesired'});
            
            t1 = tic;
            
            obj.setVelocity(1,2)
            
            while toc(t1) < 7
                pause(0.1*rand)
                
                if toc(t1) > 5
                    obj.setVelocity(1,-2);
                end
                
                obj.update();
                v = obj.getValues();
                h.putdata([
                    obj.structState(1).Value
                    obj.structState(1).DesiredValue
                    obj.structState(1).Velocity
                    obj.structState(1).DesiredVelocity
                    ]);
                
            end
            disp('done')
            
        end
    end
    methods (Static = true)
        function stateStruct = defaultState
            
            stateStruct.Name = 'new state';
            stateStruct.Value = 0;          % Typically a joint angle in radians
            stateStruct.IsReversed = 0;     % Changes sign of Value when accessed
            stateStruct.IsAccelLimited = 0; % Enable accel limiting on a per-joint basis
            stateStruct.State = 0;          % used to store Grasp Id
            stateStruct.Velocity = 0;       % set the velocity and then as time increments position will change
            stateStruct.Max = +pi;          % Max Value
            stateStruct.Min = -pi;          % Min Value
            stateStruct.MaxVelocity = 1;    % Max Velocity, either direction
            stateStruct.MaxAcceleration = 10;
            stateStruct.DefaultValue = 0;   % Typically a joint angle in radians representing the 'home' position
            stateStruct.DefaultVelocity = 0.5; % Typically speed at which home is returned to given no other command
            
            % New fields for individual joint roc assignment
            stateStruct.RocId = [];
            stateStruct.RocValue = 0;
            stateStruct.RocVelocity = 0;
            
            stateStruct.ControlMode = 'Joint';  % Future: Joint, Endpoint, ROC
            
            % These are internally updated state variables
            stateStruct.LastValue = 0;
            stateStruct.LastVelocity = 0;
            stateStruct.DesiredValue = 0;
            stateStruct.DesiredVelocity = 0;
            
        end
    end
end