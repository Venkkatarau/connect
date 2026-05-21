// App.js
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { WebView } from 'react-native-webview';

const HomeScreen = () => {
  return (
    <View style={styles.container}>
      <WebView source={{ uri: 'http://localhost:8082' }} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

export default HomeScreen;
