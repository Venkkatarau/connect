import * as React from 'react';
import { KeyboardAvoidingView, Platform } from 'react-native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Icon from 'react-native-vector-icons/Ionicons';
import ModuleAccess from './ModuleAccess';
import UserModule from './UserModule';

const Tab = createBottomTabNavigator();

export default function DashboardScreen() {
  return (
    // <NavigationContainer>
    <KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
  style={{ flex: 1 }}
>  
      <Tab.Navigator
        screenOptions={({ route, }) => ({
          tabBarIcon: ({ color, size }) => {
            let iconName: string = '';

            if (route.name === 'Users') {
              iconName = 'home';
            } else if (route.name === 'Module') {
              iconName = 'checkmark';
            }

            return <Icon name={iconName} size={size} color={color} />;
          },
          tabBarActiveTintColor: '#225663',
          tabBarInactiveTintColor: '#b4bdbf',
          headerShown: false,
        })}
      >
        <Tab.Screen name="Users" component={UserModule} />
        <Tab.Screen name="Module" component={ModuleAccess} />
       
      </Tab.Navigator>
      </KeyboardAvoidingView>
    //  </NavigationContainer>
  );
}
