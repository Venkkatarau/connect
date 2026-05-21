// ConceptVideoScreen.jsx
import React, { useRef, useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  Dimensions,
  Animated,
  TouchableOpacity,
  ActivityIndicator,
  BackHandler,
  Pressable,
  StatusBar,
  Linking
} from "react-native";
import Video from "react-native-video";
import Icon from "react-native-vector-icons/Ionicons";
import Slider from "@react-native-community/slider";
import Orientation from "react-native-orientation-locker";

const { width: SCREEN_WIDTH } = Dimensions.get("window");

const VIDEO_HEIGHT = 220;
const AUTO_HIDE_MS = 3000;
const SKIP_STEP_SECONDS = 10;
const SKIP_STACK_RESET_MS = 1000;
const DOUBLE_TAP_DELAY = 300;

const ConceptVideoScreen = ({ route }) => {
  const { concept: initialConcept, module } = route.params || {};
  const allConcepts = [
    ...(module?.concepts || []),
    ...(module?.transactionConcepts || []),
  ];

  // Core states
  const [concept, setConcept] = useState(initialConcept);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [paused, setPaused] = useState(false);

  const [controlsVisible, setControlsVisible] = useState(true);
  const [isSeeking, setIsSeeking] = useState(false);
  const [seekPosition, setSeekPosition] = useState(0);
  const [isVideoReady, setIsVideoReady] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [videoWidth, setVideoWidth] = useState(SCREEN_WIDTH);
  const [videoError, setVideoError] = useState(false);

  // Refs / timers
  const videoRef = useRef(null);
  const controlsHideTimerRef = useRef(null);
  const skipCountRef = useRef(0);
  const skipResetTimerRef = useRef(null);
  const lastTapRef = useRef(null);

  // Overlay / animation
  const videoOpacity = useRef(new Animated.Value(1)).current;
  const overlayOpacity = useRef(new Animated.Value(0)).current;
  const [overlayInfo, setOverlayInfo] = useState(null); // { type: 'forward'|'backward', seconds: number }

  // ----------------- helpers: auto-hide controls -----------------
  const clearControlsHideTimer = () => {
    if (controlsHideTimerRef.current) {
      clearTimeout(controlsHideTimerRef.current);
      controlsHideTimerRef.current = null;
    }
  };

  const startControlsHideTimer = () => {
    clearControlsHideTimer();
    controlsHideTimerRef.current = setTimeout(() => {
      setControlsVisible(false);
      controlsHideTimerRef.current = null;
    }, AUTO_HIDE_MS);
  };

  const showControlsWithAutoHide = () => {
    setControlsVisible(true);
    startControlsHideTimer();
  };

  const clearSkipStackTimer = () => {
    if (skipResetTimerRef.current) {
      clearTimeout(skipResetTimerRef.current);
      skipResetTimerRef.current = null;
    }
  };

  const clearAllTimers = () => {
    clearControlsHideTimer();
    clearSkipStackTimer();
  };

  useEffect(() => {
    return () => clearAllTimers();
  }, []);

  // ----------------- fullscreen -----------------
  const enterFullscreen = () => {
    Orientation.lockToLandscape();
    setIsFullscreen(true);
    showControlsWithAutoHide();
  };
  const exitFullscreen = () => {
    Orientation.lockToPortrait();
    setIsFullscreen(false);
    showControlsWithAutoHide();
  };
  const toggleFullscreen = () => {
    if (isFullscreen) exitFullscreen();
    else enterFullscreen();
  };

  useEffect(() => {
    const onBackPress = () => {
      if (isFullscreen) {
        exitFullscreen();
        return true;
      }
      return false;
    };
    const sub = BackHandler.addEventListener("hardwareBackPress", onBackPress);
    return () => sub.remove();
  }, [isFullscreen]);

  // ----------------- video callbacks -----------------
  const onLoad = (data) => {
    setDuration(data?.duration || 0);
    setIsVideoReady(true);
    Animated.timing(videoOpacity, {
      toValue: 1,
      duration: 200,
      useNativeDriver: true,
    }).start();
    setPaused(false);
    setVideoError(false);
    showControlsWithAutoHide();
  };

  const onProgress = (data) => {
    if (!isSeeking) setCurrentTime(data.currentTime);
  };

  const handleVideoEnd = () => {
    const idx = allConcepts.findIndex((c) => c.id === concept?.id);
    if (idx !== -1 && idx < allConcepts.length - 1) {
      prepareAndSetConcept(allConcepts[idx + 1]);
    } else {
      setControlsVisible(true);
    }
  };

  const onVideoError = (err) => {
    console.log("Video error:", err);
    setVideoError(true);
    setPaused(true);
    setControlsVisible(true);
  };

  // ----------------- seeking -----------------
  const clamp = (t) => Math.max(0, Math.min(t || 0, duration || 0));

  const seekTo = (time) => {
    const t = clamp(time);
    if (videoRef.current && typeof videoRef.current.seek === "function") {
      videoRef.current.seek(t);
    }
    setCurrentTime(t);
  };

  const seekBy = (deltaSeconds) => {
    seekTo(currentTime + deltaSeconds);
  };

  const triggerSkipOverlay = (type, seconds) => {
    setOverlayInfo({ type, seconds });
    overlayOpacity.setValue(1);
    Animated.timing(overlayOpacity, {
      toValue: 0,
      duration: 700,
      useNativeDriver: true,
    }).start(() => {
      setOverlayInfo(null);
    });
  };

  const prepareAndSetConcept = (newConcept) => {
    clearAllTimers();
    setIsSeeking(false);
    setSeekPosition(0);
    setCurrentTime(0);
    setDuration(0);
    skipCountRef.current = 0;
    videoOpacity.setValue(0);
    setIsVideoReady(false);
    setPaused(true);
    setVideoError(false);
    setConcept(newConcept);
  };

  // ----------------- slider handlers -----------------
  const onSlidingStart = () => {
    setIsSeeking(true);
    setSeekPosition(currentTime);
    clearControlsHideTimer();
  };

  const onValueChange = (val) => setSeekPosition(val);

  const onSlidingComplete = (val) => {
    seekTo(val);
    setIsSeeking(false);
    showControlsWithAutoHide();
  };

  // ----------------- playback controls -----------------
  const togglePlayPause = () => {
    setPaused((p) => !p);
    showControlsWithAutoHide();
  };

  const currentIndex = allConcepts.findIndex((c) => c.id === concept?.id);
  const isFirst = currentIndex === 0;
  const isLast = currentIndex === allConcepts.length - 1;

  const playPrevious = () => {
    if (!isFirst) {
      prepareAndSetConcept(allConcepts[currentIndex - 1]);
      showControlsWithAutoHide();
    }
  };

  const playNext = () => {
    if (!isLast) {
      prepareAndSetConcept(allConcepts[currentIndex + 1]);
      showControlsWithAutoHide();
    }
  };

  // ----------------- double tap detection -----------------
  const handleZonePress = (zone) => {
  const now = Date.now();

  if (lastTapRef.current && now - lastTapRef.current < DOUBLE_TAP_DELAY) {
    // DOUBLE TAP
    if (zone === "left") {
      skipCountRef.current += 1;
      clearSkipStackTimer();
      skipResetTimerRef.current = setTimeout(() => {
        skipCountRef.current = 0;
        skipResetTimerRef.current = null;
      }, SKIP_STACK_RESET_MS);

      const seconds = SKIP_STEP_SECONDS * skipCountRef.current;
      seekBy(-SKIP_STEP_SECONDS);
      triggerSkipOverlay("backward", seconds);
    } else if (zone === "right") {
      skipCountRef.current += 1;
      clearSkipStackTimer();
      skipResetTimerRef.current = setTimeout(() => {
        skipCountRef.current = 0;
        skipResetTimerRef.current = null;
      }, SKIP_STACK_RESET_MS);

      const seconds = SKIP_STEP_SECONDS * skipCountRef.current;
      seekBy(SKIP_STEP_SECONDS);
      triggerSkipOverlay("forward", seconds);
    }
    lastTapRef.current = null;
  } else {
    // SINGLE TAP
    lastTapRef.current = now;
    setTimeout(() => {
      if (lastTapRef.current === now) {
        // ✅ single tap should work in ALL zones
        setControlsVisible((v) => {
          if (v) {
            clearControlsHideTimer();
            return false;
          } else {
            startControlsHideTimer();
            return true;
          }
        });
        lastTapRef.current = null;
      }
    }, DOUBLE_TAP_DELAY);
  }
};

  // ----------------- helpers -----------------
  const onVideoLayout = (e) =>
    setVideoWidth(e?.nativeEvent?.layout?.width || SCREEN_WIDTH);

  const formatTime = (time) => {
    if (time == null || isNaN(time)) return "0:00";
    const m = Math.floor(time / 60);
    const s = Math.floor(time % 60);
    return `${m}:${s < 10 ? "0" : ""}${s}`;
  };

  const filteredConcepts = (module?.concepts || []).filter(
    (c) => c.id !== concept?.id
  );
  const filteredTransactions = (module?.transactionConcepts || []).filter(
    (c) => c.id !== concept?.id
  );

  // ----------------- JSX -----------------
  return (
    <View style={styles.container}>
            <StatusBar barStyle="light-content" backgroundColor="#000000ff" />
      000000f1
      <View
        style={[
          styles.videoWrapper,
          isFullscreen && styles.videoWrapperFullscreen,
        ]}
        onLayout={onVideoLayout}
      >
        {/* Video */}
        <Animated.View
          style={[styles.videoAnimatedWrap, { opacity: videoOpacity }]}
        >
          {videoError ? (
            <View style={styles.errorOverlay}>
              <Icon name="alert-circle" size={50} color="#fff" />
              <Text style={styles.errorText}>
                Failed to load video (Server error 500)
              </Text>
            </View>
          ) : (
            <Video
              key={concept?.id ?? "video"}
              ref={videoRef}
              source={
                concept?.videoUrl
                  ? {
                      uri: encodeURI(`https://dbp6bbvk4lzrp.cloudfront.net/${concept.videoUrl}`),
                    }
                  : undefined
              }
              style={styles.video}
              resizeMode="contain"
              paused={paused}
              onLoad={onLoad}
              onProgress={onProgress}
              onEnd={handleVideoEnd}
              onError={onVideoError}
              controls={false}
            />
          )}
        </Animated.View>

        {/* Touch overlay zones */}
        <View style={styles.touchOverlay}>
          <View style={styles.touchRow}>
            <Pressable
              style={styles.leftZone}
              onPress={() => handleZonePress("left")}
            />
            <Pressable
              style={styles.centerZone}
              onPress={() => handleZonePress("center")}
            />
            <Pressable
              style={styles.rightZone}
              onPress={() => handleZonePress("right")}
            />
          </View>
        </View>

        {/* Skip overlay */}
        {overlayInfo && (
          <Animated.View
            pointerEvents="none"
            style={[
              styles.skipOverlay,
              overlayInfo.type === "forward"
                ? { right: 36, alignItems: "flex-end" }
                : { left: 36, alignItems: "flex-start" },
              { opacity: overlayOpacity },
            ]}
          >
            <Icon
              name={overlayInfo.type === "forward" ? "play-forward" : "play-back"}
              size={34}
              color="#fff"
            />
            <Text style={styles.skipText}>{overlayInfo.seconds}s</Text>
          </Animated.View>
        )}

        {/* Loader */}
        {!isVideoReady && !videoError && (
          <View style={styles.loadingOverlay} pointerEvents="none">
            <ActivityIndicator size="large" color="#fff" />
          </View>
        )}

        {/* Controls */}
        {controlsVisible && (
          <>
            <View style={styles.centerControls} pointerEvents="box-none">
              <TouchableOpacity
                onPress={playPrevious}
                disabled={isFirst}
                style={styles.iconBtn}
                activeOpacity={0.7}
              >
                <Icon
                  name="play-skip-back"
                  size={28}
                  color={isFirst ? "#666" : "#fff"}
                />
              </TouchableOpacity>

              <TouchableOpacity
                onPress={togglePlayPause}
                style={styles.iconBtn}
                activeOpacity={0.7}
              >
                <Icon name={paused ? "play" : "pause"} size={36} color="#fff" />
              </TouchableOpacity>

              <TouchableOpacity
                onPress={playNext}
                disabled={isLast}
                style={styles.iconBtn}
                activeOpacity={0.7}
              >
                <Icon
                  name="play-skip-forward"
                  size={28}
                  color={isLast ? "#666" : "#fff"}
                />
              </TouchableOpacity>
            </View>

            <View style={styles.bottomBar} pointerEvents="box-none">
              <View style={styles.timeBubble}>
                <Text style={styles.timeText}>
                  {formatTime(isSeeking ? seekPosition : currentTime)} /{" "}
                  {formatTime(duration)}
                </Text>
              </View>

              <Slider
                style={styles.slider}
                minimumValue={0}
                maximumValue={duration || 0}
                value={isSeeking ? seekPosition : currentTime}
                minimumTrackTintColor="#225663"
                maximumTrackTintColor="#ffffff"
                thumbTintColor="#225663"
                onSlidingStart={onSlidingStart}
                onValueChange={onValueChange}
                onSlidingComplete={onSlidingComplete}
              />

              <TouchableOpacity
                onPress={toggleFullscreen}
                style={styles.fullscreenBtn}
                activeOpacity={0.8}
              >
                <Icon
                  name={isFullscreen ? "contract" : "expand"}
                  size={20}
                  color="#fff"
                />
              </TouchableOpacity>
            </View>
          </>
        )}
      </View>

      {/* Below video */}
      {!isFullscreen && (
        <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
          <Text style={styles.chapterTitle}>{concept?.title}</Text>

          {concept?.supportingDocuments && concept.supportingDocuments.length > 0 && (
            <View style={styles.docsContainer}>
              <Text style={styles.docsHeader}>Supporting Documents</Text>
              {concept.supportingDocuments.map((doc, idx) => {
                const displayName = doc.split('_').slice(1).join('_') || `Document ${idx + 1}`;
                const fileUrl = `https://dbp6bbvk4lzrp.cloudfront.net/${doc}`;
                return (
                  <TouchableOpacity
                    key={idx}
                    style={styles.docRow}
                    onPress={() => {
                      Linking.openURL(encodeURI(fileUrl)).catch((err) =>
                        console.error("Failed to open document URL", err)
                      );
                    }}
                  >
                    <Icon name="document-text-outline" size={22} color="#225663" style={{ marginRight: 10 }} />
                    <Text style={styles.docName} numberOfLines={1}>
                      {displayName}
                    </Text>
                    <Icon name="download-outline" size={18} color="#666" style={{ marginLeft: "auto" }} />
                  </TouchableOpacity>
                );
              })}
            </View>
          )}

          <View style={styles.conceptList}>
            {filteredConcepts.length > 0 && (
              <>
                <Text style={styles.subHeader}>SetUp:——&gt;</Text>
                {filteredConcepts.map((c) => renderConcept(c))}
              </>
            )}
            {filteredTransactions.length > 0 && (
              <>
                <Text style={styles.subHeader}>Transaction:—&gt;</Text>
                {filteredTransactions.map((c) => renderConcept(c))}
              </>
            )}
          </View>
        </ScrollView>
      )}
    </View>
  );

  function renderConcept(item) {
    return (
      <TouchableOpacity
        key={item.id}
        onPress={() => prepareAndSetConcept(item)}
      >
        <View style={styles.conceptRow}>
          {item.thumbnailFileName ? (
            <View style={styles.thumbWrap}>
              <Image
                source={{
                  uri: encodeURI(`https://dbp6bbvk4lzrp.cloudfront.net/${item.thumbnailFileName}`),
                }}
                style={styles.thumbnail}
              />
              <View style={styles.playBadge}>
                <Icon name="play-circle" size={18} color="gray" />
              </View>
            </View>
          ) : (
            <View style={[styles.thumbnail, { backgroundColor: "#ddd" }]} />
          )}
          <View style={{ flex: 1 }}>
            <Text style={styles.conceptTitle}>{item.title}</Text>
          </View>
        </View>
      </TouchableOpacity>
    );
  }
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#fff" },
  videoWrapper: {
    height: VIDEO_HEIGHT,
    backgroundColor: "#000",
    overflow: "hidden",
  },
  videoAnimatedWrap: { width: "100%", height: "100%" },
  video: { width: "100%", height: "100%" },
  touchOverlay: { ...StyleSheet.absoluteFillObject, zIndex: 40 },
  touchRow: { flex: 1, flexDirection: "row" },
  leftZone: { flex: 3 },
  centerZone: { flex: 4 },
  rightZone: { flex: 3 },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: "center",
    alignItems: "center",
  },
  skipOverlay: {
    position: "absolute",
    top: "40%",
    justifyContent: "center",
    zIndex: 50,
  },
  skipText: { color: "#fff", fontSize: 13, marginTop: 4, fontWeight: "600" },
  centerControls: {
    position: "absolute",
    top: "36%",
    left: 0,
    right: 0,
    flexDirection: "row",
    justifyContent: "space-around",
    alignItems: "center",
    zIndex: 45,
    paddingHorizontal: 24,
  },
  iconBtn: { padding: 10 },
  bottomBar: {
    position: "absolute",
    left: 8,
    right: 8,
    bottom: 8,
    zIndex: 45,
    backgroundColor: "transparent",
    padding: 6,
    borderRadius: 8,
    flexDirection: "row",
    alignItems: "center",
  },
  timeBubble: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(0,0,0,0.5)",
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 10,
    marginRight: 8,
  },
  timeText: { color: "#fff", fontSize: 12 },
  slider: { flex: 1 },
  chapterTitle: {
    fontSize: 20,
    fontWeight: "bold",
    marginTop: 16,
    marginHorizontal: 16,
    color: "#2d2d2d",
  },
  conceptList: { padding: 10, backgroundColor: "#fff" },
  conceptRow: { flexDirection: "row", alignItems: "center", marginVertical: 6 },
  thumbWrap: { position: "relative", width: 50, height: 50, marginRight: 10 },
  thumbnail: { width: 50, height: 50, borderRadius: 6 },
  playBadge: {
    position: "absolute",
    top: "50%",
    left: "50%",
    transform: [{ translateX: -10 }, { translateY: -10 }],
  },
  conceptTitle: { fontSize: 14, fontWeight: "600", color: "#000" },
  moduleTitle: { fontSize: 16, fontWeight: "bold" },
  subHeader: { fontSize: 14, fontWeight: "bold", marginVertical: 6 },
  fullscreenBtn: { marginLeft: 8, padding: 6 },
  videoWrapperFullscreen: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    height: "100%",
    width: "100%",
    backgroundColor: "#000",
    zIndex: 999,
  },
  errorOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#000",
  },
  errorText: { color: "#fff", fontSize: 16, marginTop: 12 },
  docsContainer: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#eee",
  },
  docsHeader: {
    fontSize: 16,
    fontWeight: "bold",
    marginBottom: 10,
    color: "#225663",
  },
  docRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 10,
    borderBottomWidth: 0.5,
    borderBottomColor: "#eee",
  },
  docName: {
    fontSize: 14,
    color: "#333",
    flex: 1,
  },
});

export default ConceptVideoScreen;
