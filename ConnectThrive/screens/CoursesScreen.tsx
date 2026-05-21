import React, { useEffect, useState } from "react";
import { BASE_URL } from '../config/api';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  FlatList,
  Image,
  ActivityIndicator,
  ScrollView,
  StatusBar,
  RefreshControl,
  Alert
} from "react-native";
import Icon from "react-native-vector-icons/Ionicons";
import { useNavigation } from "@react-navigation/native";
import { globalUser } from '../config/globalUser';

type Concept = {
  id: number;
  title: string;
  videoUrl: string;
  thumbnailFileName: string;
  videoType: string;
  supportingDocuments: string[];
};

type Module = {
  id: number;
  name: string;
  tier: string;
  description: string | null;
  accessible: boolean;
  concepts: Concept[];
  transactionConcepts: Concept[];
};

const CoursesScreen = () => {
  const [modules, setModules] = useState<Module[]>([]);
  const [expandedModule, setExpandedModule] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const navigation = useNavigation<any>();
  const [accessLoadingModuleId, setAccessLoadingModuleId] = useState<number | null>(null);

  useEffect(() => {
    fetchModules();
  }, []);

  const requestModuleAccess = async (moduleId: number) => {
    setAccessLoadingModuleId(moduleId); // Start loading spinner for this module
    try {
      const res = await fetch(`${BASE_URL}/api/modules/${moduleId}/request-access?userId=${globalUser.userId}`, {
        method: "POST",
      });

      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`);
      }

      const data = await res.json();
      console.log("Access request response:", data);
      Alert.alert(data.message || "Access request sent successfully");

      // Optional: refresh module list to update access status
      // fetchModules();
    } catch (error) {
      console.error("Error requesting access to module", error);
    } finally {
      setAccessLoadingModuleId(null); // Stop loading spinner
    }
  };


  const fetchModules = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${BASE_URL}/v1/admin/${globalUser.batchId}/modules?userId=${globalUser.userId}`);
      if (!res.ok) {
        console.warn(`Modules API returned status ${res.status}`);
        setModules([]);
        return;
      }
      const data = await res.json();
      setModules(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error("Error fetching modules", error);
      setModules([]);
    } finally {
      setLoading(false);
    }
  };

  const toggleExpand = (id: number) => {
    setExpandedModule(expandedModule === id ? null : id);
  };

  const renderConcept = (item: Concept, module: Module) => (
    <TouchableOpacity
      style={styles.conceptRow}
      key={item.id}
      onPress={() => {
        if (module.accessible) {
          navigation.navigate("ConceptVideo", { concept: item, module: module })
        }
      }}
      activeOpacity={module.accessible ? 0.2 : 1}
    >
      {item.thumbnailFileName ? (
        <View style={styles.Imagecontainer}>
          <Image
            source={{ uri: encodeURI(`https://dbp6bbvk4lzrp.cloudfront.net/${item.thumbnailFileName}`) }}
            style={styles.thumbnail}
          />
          <View style={styles.playIconContainer}>
            <Icon name="play-circle" size={20} color="gray" />
          </View>
        </View>
      ) : (
        <View style={[styles.thumbnail, { backgroundColor: "#ddd" }]} />
      )}
      <View style={{ flex: 1 }}>
        <Text style={styles.conceptTitle}>{item.title}</Text>
      </View>
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <View style={styles.loader}>
        <ActivityIndicator size="large" color="#225663" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} refreshControl={<RefreshControl refreshing={loading} onRefresh={fetchModules} />}>
      <View style={styles.headerRow}>
        <Text style={styles.headerTitle}>Oracle Fusion Financials</Text>
      </View>
      <Text style={styles.sectionTitle}>Outcome</Text>
      <Text style={styles.description}>Connect Thrive Technologies is your all-in-one mobile app to learn Oracle Fusion Financials on the go. Access module-wise concept videos (GL, AP, AR, FA, CM), real-time scenarios, interview Q&A, and advanced topics—all in one place. Ideal for job seekers and professionals aiming to master Oracle Fusion.</Text>
      {modules.map((module) => (
        <View key={module.id} style={[styles.moduleCard, { borderColor: module.accessible ? "#fff" : "#e0e0e0" }]}>
          <TouchableOpacity
            style={[styles.moduleHeader, { backgroundColor: module.accessible ? "#fff" : "#e0e0e0" }]}
            onPress={() => toggleExpand(module.id)}
          >
            <Text style={styles.moduleTitle}>{module.name}</Text>
            <View style={styles.iconContainer}>
              {!module.accessible && (
                accessLoadingModuleId === module.id ? (
                  <ActivityIndicator size="small" color="#000" />
                ) : (
                  <TouchableOpacity onPress={() => requestModuleAccess(module.id)}>
                    <Icon name="lock-closed-outline" size={20} color="#000" />
                  </TouchableOpacity>
                )
              )}
              <Icon
                name={expandedModule === module.id ? "chevron-up-outline" : "chevron-down-outline"}
                size={20}
                color="#000"
              />
            </View>
          </TouchableOpacity>
          {expandedModule === module.id && (
            <View style={[styles.conceptList, { backgroundColor: module.accessible ? "#fff" : "#e0e0e0" }]}>
              {module.concepts.length > 0 && (
                <View>
                  <Text style={styles.subHeader}>SetUp:——&gt;</Text>
                  {module.concepts.map((concept) => renderConcept(concept, module))}
                </View>
              )}
              {module.transactionConcepts.length > 0 && (
                <View>
                  <Text style={styles.subHeader}>Transaction:—&gt;</Text>
                  {module.transactionConcepts.map((concept) => renderConcept(concept, module))}
                </View>
              )}
              {module.concepts.length === 0 && module.transactionConcepts.length === 0 && (
                <Text style={styles.emptyText}>No concepts available</Text>
              )}
            </View>
          )}
        </View>
      ))}
    </ScrollView>
  );
};

export default CoursesScreen;

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: "#f1f4f9" },
  sectionTitle: { fontSize: 18, fontWeight: "bold", marginBottom: 12 },
  moduleCard: {
    borderWidth: 1,
    borderColor: "#fff",
    borderRadius: 8,
    marginBottom: 12,
    overflow: "hidden",
  },
  modulelockCard: {
    borderWidth: 1,
    borderColor: "#301e1e28",
    borderRadius: 8,
    marginBottom: 12,
    overflow: "hidden",
  },
  moduleHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    padding: 12,
    backgroundColor: "#fff",
  },
  moduleTitle: { fontSize: 16, fontWeight: "bold" },
  conceptList: { padding: 10, backgroundColor: "#fff" },
  subHeader: { fontSize: 14, fontWeight: "bold", marginVertical: 6 },
  conceptRow: { flexDirection: "row", alignItems: "center", marginVertical: 6 },
  thumbnail: { width: 50, height: 50, borderRadius: 6, marginRight: 10 },
  conceptTitle: { fontSize: 14, fontWeight: "600" },
  conceptSubtitle: { fontSize: 12, color: "#777" },
  emptyText: { fontSize: 12, color: "#888", fontStyle: "italic" },
  loader: { flex: 1, justifyContent: "center", alignItems: "center" },
  description: { fontSize: 14, color: "#444", lineHeight: 20 },
  headerRow: { flexDirection: "row", alignItems: "center", marginBottom: 12 },
  headerTitle: { fontSize: 18, fontWeight: "bold", marginLeft: 10 },
  playIconContainer: {
    position: 'absolute',
    top: '50%',
    left: '50%',
    transform: [
      { translateX: -10 }, // Half of icon size (for 20x20 icon)
      { translateY: -10 },
    ],
    justifyContent: 'center',
    alignItems: 'center',
  },
  Imagecontainer: {
    position: 'relative',
    width: 50,
    height: 50,
    borderRadius: 6, marginRight: 10
  },
  iconContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8, // use if using React Native 0.71+, otherwise use marginRight
  },
});
