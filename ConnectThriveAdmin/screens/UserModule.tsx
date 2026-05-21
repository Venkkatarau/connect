import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Modal,
  Button,
  ActivityIndicator,
  TextInput,
} from "react-native";
import Icon from "react-native-vector-icons/Ionicons";
import { BASE_URL } from "../config/api";

const UserModule = () => {
  const [users, setUsers] = useState([]);
  const [filteredUsers, setFilteredUsers] = useState([]);
  const [batches, setBatches] = useState([]);
  const [loading, setLoading] = useState(false);
  const [batchLoading, setBatchLoading] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [modalVisible, setModalVisible] = useState(false);
  const [selectedBatches, setSelectedBatches] = useState([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedBatch, setSelectedBatch] = useState(null);

  // select function
  const selectBatch = (batchId) => {
    setSelectedBatch(batchId); // only one at a time
  };
  // Fetch users + batches on mount
  useEffect(() => {
    fetchUsers();
    fetchBatches();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const res = await fetch(
        `${BASE_URL}/v1/getUserList`
      );
      const data = await res.json();
      if (Array.isArray(data)) {
        setUsers(data);
        setFilteredUsers(data);
      } else {
        setUsers([]);
        setFilteredUsers([]);
      }
    } catch (error) {
      console.error("Error fetching users:", error);
      setUsers([]);
      setFilteredUsers([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchBatches = async () => {
    try {
      setLoading(true);
      const res = await fetch(
        `${BASE_URL}/v1/admin/getAllBatches`
      );
      const data = await res.json();
      setBatches(data);
    } catch (error) {
      console.error("Error fetching batches:", error);
    } finally {
      setLoading(false);
    }
  };


  const handleSubmit = async () => {
    if (!selectedUser || !selectedBatch) {
      alert("Please select a batch");
      return;
    }

    try {
      setBatchLoading(true);

      const res = await fetch(
        `${BASE_URL}/v1/users/updateBatch/${selectedUser.id}?batchId=${selectedBatch}`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (!res.ok) {
        throw new Error("Failed to update batch");
      }

      alert("Batch updated successfully!");
      fetchUsers(); // refresh users

      // reset modal state
      setSearchQuery("");
      setModalVisible(false);
      setSelectedBatch(null);
    } catch (error) {
      console.error("Error updating batch:", error);
      alert("Error updating batch");
    } finally {
      setBatchLoading(false);
    }
  };


  const handleSearch = (text) => {
    setSearchQuery(text);
    if (text.trim() === "") {
      setFilteredUsers(users);
    } else {
      const lower = text.toLowerCase();
      const filtered = users.filter(
        (u) =>
          u.username.toLowerCase().includes(lower) ||
          u.mobileNumber.includes(text)
      );
      setFilteredUsers(filtered);
    }
  };

  const renderUser = ({ item }) => (
    <View style={styles.card}>
      <View>
        <Text style={styles.text}>Name: {item.username}</Text>
        <Text style={styles.text}>Phone: {item.mobileNumber}</Text>
        <Text style={styles.text}>Batch: {item.batchName}</Text>
      </View>
      <TouchableOpacity
        onPress={() => {
          setSelectedUser(item);
          setModalVisible(true);
        }}
      >
        <Icon name="pencil-outline" size={20} />
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      {/* Search Bar */}


      <View style={styles.searchContainer}>
        <TextInput
          style={styles.searchInput}
          placeholder="Search by name or phone..."
          value={searchQuery}
          onChangeText={handleSearch}
        />
        <Icon name="search" size={20} color="#666" style={styles.searchIcon} />
      </View>

      {loading ? (
        <ActivityIndicator size="large" color="#000" />
      ) : (
        <FlatList
          data={filteredUsers}
          renderItem={renderUser}
          keyExtractor={(item) => item.id.toString()}
          ListEmptyComponent={
            <Text style={{ textAlign: "center", marginTop: 20 }}>
              No users found
            </Text>
          }
        />
      )}

      {/* Modal for batch selection */}
      <Modal
        visible={modalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalBackground}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Batch List</Text>

            {batchLoading ? (
              <ActivityIndicator size="small" color="#000" />
            ) : (
              batches.map((batch) => (
                <TouchableOpacity
                  key={batch.id}
                  style={styles.batchItem}
                  onPress={() => selectBatch(batch.id)}
                >
                  <Icon
                    name={
                      selectedBatch === batch.id
                        ? "radio-button-on-outline"
                        : "radio-button-off-outline"
                    }
                    size={22}
                    color="#000"
                  />
                  <Text style={styles.batchText}>{batch.name}</Text>
                </TouchableOpacity>
              ))
            )}


            <Button title="Submit" color="#225663" onPress={handleSubmit} />
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 15,
  },
  searchInput: {
    flex: 1,
    height: 45,
    fontSize: 14,
  },
  card: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    backgroundColor: "#f9f9f9",
    padding: 15,
    marginBottom: 10,
    borderRadius: 8,
    elevation: 2,
  },
  text: {
    fontSize: 16,
    marginBottom: 4,
  },
  modalBackground: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.5)",
  },
  modalContent: {
    backgroundColor: "#fff",
    padding: 20,
    width: "80%",
    borderRadius: 10,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 15,
    textAlign: 'center',
  },
  batchItem: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 12,
  },
  batchText: {
    fontSize: 16,
    marginLeft: 10,
  },
  searchContainer: {
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    backgroundColor: "#fff",
    paddingHorizontal: 10,
    marginBottom: 12,
  },
});

export default UserModule;
