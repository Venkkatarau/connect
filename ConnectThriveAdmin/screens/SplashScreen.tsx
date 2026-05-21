
import { View, Image, StyleSheet, StatusBar } from 'react-native';
import React, { useEffect, useState } from "react";
import { useNavigation } from "@react-navigation/native";
const SplashScreen = () => {
    const navigation = useNavigation();
  const [seconds, setSeconds] = useState(5);

useEffect(() => {
  if (seconds === 0) {
    navigation.replace("Login"); // 👈 Assuming "Login" is in your stack
    return;
  }

  const timer = setTimeout(() => {
    setSeconds((prev) => prev - 1);
  }, 1000);

  return () => clearTimeout(timer);
}, [seconds]);
  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#225663" />
      <Image
        source={require('./../assets/logo.png')} // put your logo file in assets folder
        style={styles.logo}
        resizeMode="contain"
      />
    </View>
  );
};

export default SplashScreen;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#225663', // purple background
    justifyContent: 'center',
    alignItems: 'center',
  },
  logo: {
    width: 220,
    height: 80,
  },
});
