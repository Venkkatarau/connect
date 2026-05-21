import * as React from 'react';
// import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import Icon from 'react-native-vector-icons/Ionicons';
import { Text, View } from 'react-native';
import CoursesScreen from './CoursesScreen';
import HomeScreen from './HomeScreen';
import AccountScreen from './AccountScreen';


const Tab = createBottomTabNavigator();

export default function DashboardScreen() {
  return (
    // <NavigationContainer>
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ color, size }) => {
          let iconName: string = '';

          if (route.name === 'Home') {
            iconName = 'home';
          } else if (route.name === 'Courses') {
            iconName = 'book';
          } else if (route.name === 'Account') {
            iconName = 'person';
          }

          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: '#225663',
        tabBarInactiveTintColor: '#b4bdbf',
        headerShown: false,
      })}
    >
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Courses" component={CoursesScreen} />
      <Tab.Screen name="Account" component={AccountScreen} />
    </Tab.Navigator>
    //  </NavigationContainer>
  );
}
