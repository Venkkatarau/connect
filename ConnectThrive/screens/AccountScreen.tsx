import React, { useState } from "react";
import { useNavigation } from "@react-navigation/native";
import { globalUser } from "../config/globalUser";

import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  ScrollView,
} from "react-native";
const AccountScreen = () => {
  const [screen, setScreen] = useState("account"); // account | about | help | login
  const navigation = useNavigation<any>();
  const user = {
    name: globalUser.name,
    phone: globalUser.phone.startsWith("+91") ? globalUser.phone : `+91 ${globalUser.phone}`,
  };

  const getInitials = (fullName: string) => {
    const names = fullName.split(" ");
    let initials = names[0].charAt(0);
    if (names.length > 1) {
      initials += names[names.length - 1].charAt(0);
    }
    return initials.toUpperCase();
  };

  // "Screens"
  if (screen === "about") {
    return (
      <SafeAreaView style={styles.centerScreen}>
        <Text style={styles.hiText}>hi (About App)</Text>
        <TouchableOpacity onPress={() => setScreen("account")}>
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
      </SafeAreaView>
    );
  }

  if (screen === "help") {
    return (
      <SafeAreaView style={styles.centerScreen}>
        <Text style={styles.hiText}>hi (Help & Support)</Text>
        <TouchableOpacity onPress={() => setScreen("account")}>
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
      </SafeAreaView>
    );
  }

  if (screen === "login") {
    return (
      <SafeAreaView style={styles.centerScreen}>
        <Text style={styles.hiText}>You are now at Login Screen</Text>
      </SafeAreaView>
    );
  }

  // Main Account Screen
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={{ flexGrow: 1 }}>
        {/* Profile */}
        <View style={styles.profileContainer}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{getInitials(user.name)}</Text>
          </View>
          <Text style={styles.name}>{user.name}</Text>
          <Text style={styles.phone}>{user.phone}</Text>
        </View>

        {/* Support Section */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle}>Support</Text>

          <TouchableOpacity
            style={styles.option}
            onPress={() => setScreen("about")}
          >
            <Text style={styles.optionText}>About App</Text>
            <Text style={styles.arrow}>›</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.option}
            onPress={() => setScreen("help")}
          >
            <Text style={styles.optionText}>Help and Support</Text>
            <Text style={styles.arrow}>›</Text>
          </TouchableOpacity>
        </View>

        {/* Sign out */}
        <TouchableOpacity
          style={styles.signOutButton}
          onPress={() => navigation.replace("Login")}
        >
          <Text style={styles.signOutText}>Sign out</Text>
        </TouchableOpacity>

        {/* App version */}
        <Text style={styles.versionText}>v1.0.0</Text>
      </ScrollView>
    </SafeAreaView>
  );
};

export default AccountScreen;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  profileContainer: {
    alignItems: "center",
    paddingTop: 40,
    paddingBottom: 30,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: "#225663",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 15,
  },
  avatarText: {
    color: "#fff",
    fontSize: 30,
    fontWeight: "bold",
  },
  name: {
    fontSize: 25,
    fontWeight: "600",
    marginBottom: 10,
  },
  phone: {
    fontSize: 18,
    color: "#666",
  },
  sectionContainer: {
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  sectionTitle: {
    fontSize: 14,
    color: "#888",
    marginBottom: 10,
    fontWeight: "500",
  },
  option: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: "#eee",
  },
  optionText: {
    fontSize: 16,
    color: "#000",
  },
  arrow: {
    fontSize: 22,
    color: "#888",
  },
  signOutButton: {
    marginTop: 30,
    alignItems: "center",
  },
  signOutText: {
    fontSize: 16,
    fontWeight: "600",
    color: "#225663",
  },
  versionText: {
    textAlign: "center",
    color: "#666",
    fontSize: 12,
    marginTop: 10,
    marginBottom: 20,
  },
  centerScreen: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  hiText: {
    fontSize: 22,
    fontWeight: "600",
    marginBottom: 20,
  },
  backText: {
    fontSize: 16,
    color: "#225663",
  },
});
