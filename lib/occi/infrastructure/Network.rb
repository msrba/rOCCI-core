##############################################################################
#  Copyright 2011 Service Computing group, TU Dortmund
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##############################################################################

##############################################################################
# Description: OCCI Infrastructure Network
# Author(s): Hayati Bice, Florian Feldhaus, Piotr Kasprzak
##############################################################################

require 'occi/core/Kind'
require 'occi/StateMachine'

module OCCI
  module Infrastructure
    class Network < OCCI::Core::Resource

      # Define associated kind
      begin
        # Define actions
        ACTION_DOWN = OCCI::Core::Action.new(scheme = "http://schemas.ogf.org/occi/infrastructure/network/action#", term = "down",      title = "Network Action Down", attributes = [])
        ACTION_UP   = OCCI::Core::Action.new(scheme = "http://schemas.ogf.org/occi/infrastructure/network/action#", term = "up",        title = "Network Action Up", attributes = [])

        actions = [ACTION_DOWN, ACTION_UP]

        # Define state-machine
        STATE_INACTIVE  = OCCI::StateMachine::State.new("inactive")
        STATE_ACTIVE    = OCCI::StateMachine::State.new("active")
        
        STATE_INACTIVE.add_transition(ACTION_UP, STATE_ACTIVE)

        STATE_ACTIVE.add_transition(ACTION_DOWN, STATE_INACTIVE)

        related     = [OCCI::Core::Resource::KIND]
        entity_type = self
        entities    = []

        term    = "network"
        scheme  = "http://schemas.ogf.org/occi/infrastructure#"
        title   = "Network Resource"

        attributes = OCCI::Core::Attributes.new()
        attributes << OCCI::Core::Attribute.new(name = 'occi.network.vlan',   mutable = true,   mandatory = false,  unique = true)
        attributes << OCCI::Core::Attribute.new(name = 'occi.network.label',  mutable = true,   mandatory = false,  unique = true)
        attributes << OCCI::Core::Attribute.new(name = 'occi.network.state',  mutable = false,  mandatory = true,   unique = true)
          
        KIND = OCCI::Core::Kind.new(actions, related, entity_type, entities, term, scheme, title, attributes)
      end

      def initialize(attributes, mixins=[])
        @state_machine  = OCCI::StateMachine.new(STATE_INACTIVE, [STATE_INACTIVE, STATE_ACTIVE], :on_transition => self.method(:update_state))
        # Initialize resource state
        attributes['occi.network.state'] = state_machine.current_state.name
        super(attributes, OCCI::Infrastructure::Network::KIND, mixins)
      end
      
      def deploy
        $backend.create_network_instance(self)
      end
      
      def refresh
        $backend.network_refresh_instance(self)
      end
      
      def delete
        $backend.delete_network_instance(self)
        delete_entity()
      end

      def update_state
        @attributes['occi.network.state'] = state_machine.current_state.name
      end

    end
  end
end
