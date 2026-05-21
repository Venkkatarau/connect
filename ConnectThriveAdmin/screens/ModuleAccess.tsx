import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  TextInput,
} from "react-native";
import Icon from "react-native-vector-icons/Ionicons";
import { BASE_URL } from "../config/api";

const RequestCard = ({ item, onApprove, onReject, loadingIds }) => {
  const isLoading = loadingIds.includes(item.id);

  return (
    <View style={styles.card}>
      <Text style={styles.text}>Name: {item.username}</Text>
      <Text style={styles.text}>Mobile No: {item.mobileNumber}</Text>
      <Text style={styles.text}>Module Name: {item.moduleName}</Text>

      <View style={styles.actions}>
        {isLoading ? (
          <ActivityIndicator size="small" color="green" />
        ) : (
          <TouchableOpacity
            style={styles.approveBtn}
            onPress={() => onApprove(item.id)}
          >
            <Icon name="checkmark" size={20} color="#fff" />
          </TouchableOpacity>
        )}

        {/* If you want reject with loader too, do the same pattern */}
        {/* <TouchableOpacity style={styles.rejectBtn} onPress={() => onReject(item.id)}>
          <Icon name="close" size={20} color="#fff" />
        </TouchableOpacity> */}
      </View>
    </View>
  );
};

const ModuleAccess = () => {
  const [requests, setRequests] = useState([]);
  const [filteredRequests, setFilteredRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [error, setError] = useState("");
  const [loadingIds, setLoadingIds] = useState([]); // track item-wise loaders

  // Fetch pending requests
  const fetchRequests = async () => {
    try {
      const res = await fetch(
        `${BASE_URL}/api/modules/pending-requests`
      );
      const data = await res.json();
      setRequests(data);
      setFilteredRequests(data);
    } catch (error) {
      console.error("Error fetching requests:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRequests();
  }, []);

  // Handle search filtering
  const handleSearch = (text) => {
    setSearch(text);
    if (text.trim() === "") {
      setFilteredRequests(requests);
    } else {
      const lower = text.toLowerCase();
      const filtered = requests.filter(
        (item) =>
          item.username.toLowerCase().includes(lower) ||
          item.mobileNumber.toLowerCase().includes(lower)
      );
      setFilteredRequests(filtered);
    }
  };

  const handleApprove = async (id) => {
    setLoadingIds((prev) => [...prev, id]); // show loader for this item
    try {
      const response = await fetch(
        `${BASE_URL}/api/modules/approve/` + id
      );

      const data = await response.json();
      console.log("approval response:", data);

      if (!response.ok) {
        setError("Something went wrong. Please try again.");
        throw new Error("Something went wrong. Please try again.");
      }

      if (response.ok && data.status === false) {
        setError(data.message);
        throw new Error(data.message);
      }

      // remove item after success
      setRequests((prev) => prev.filter((req) => req.id !== id));
      setFilteredRequests((prev) => prev.filter((req) => req.id !== id));
    } catch (error) {
      console.error("Error during approve:", error);
    } finally {
      setLoadingIds((prev) => prev.filter((loadingId) => loadingId !== id)); // hide loader
    }
  };

  const handleReject = (id) => {
    console.log("Rejected:", id);
    setRequests((prev) => prev.filter((req) => req.id !== id));
    setFilteredRequests((prev) => prev.filter((req) => req.id !== id));
  };

  if (loading) {
    return (
      <View style={styles.loader}>
        <ActivityIndicator size="large" color="#000" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* 🔍 Search Bar */}
      <View style={styles.searchContainer}>
        <TextInput
          style={styles.searchInput}
          placeholder="Search by name or mobile number"
          value={search}
          onChangeText={handleSearch}
        />
        <Icon name="search" size={20} color="#666" style={styles.searchIcon} />
      </View>

      <FlatList
        data={filteredRequests}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <RequestCard
            item={item}
            onApprove={handleApprove}
            onReject={handleReject}
            loadingIds={loadingIds}
          />
        )}
        ListEmptyComponent={
          <Text style={{ textAlign: "center", marginTop: 20 }}>
            No matching requests
          </Text>
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 15,
    backgroundColor: "#f9f9f9",
  },
  card: {
    backgroundColor: "#fff",
    padding: 15,
    borderRadius: 10,
    marginBottom: 12,
    elevation: 3,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 3,
  },
  text: {
    fontSize: 14,
    marginBottom: 5,
  },
  actions: {
    flexDirection: "row",
    justifyContent: "flex-end",
    marginTop: 10,
  },
  approveBtn: {
    backgroundColor: "green",
    padding: 10,
    borderRadius: 6,
    marginRight: 10,
  },
  rejectBtn: {
    backgroundColor: "red",
    padding: 10,
    borderRadius: 6,
  },
  loader: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
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
  searchInput: {
    flex: 1,
    height: 45,
    fontSize: 14,
  },
  searchIcon: {
    marginLeft: 8,
  },
});

export default ModuleAccess;
