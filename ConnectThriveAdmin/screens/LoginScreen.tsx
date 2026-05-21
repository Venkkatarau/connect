import React, { useState, useEffect, useRef } from 'react';
import { useNavigation } from "@react-navigation/native";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StatusBar,
  Keyboard,
  NativeSyntheticEvent,
  ActivityIndicator,
  Image,
  TextInputKeyPressEvent,
} from 'react-native';
import { BASE_URL } from '../config/api';

const LoginScreen = () => {
  const [isOtpScreen, setOtpScreen] = useState(false);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [mobileNumber, setMobileNumber] = useState('');
  const [timer, setTimer] = useState(60);
  const [otp, setOtp] = useState(["", "", "", ""]);
  const inputsRef = useRef<(TextInput | null)[]>([]);
  const [loading, setLoading] = useState(false);
  const navigation = useNavigation();
  const [error, setError] = useState("");


  const handleSignupWithOtp = async (enteredOtp: string[]) => {
    try {
      const response = await fetch(`${BASE_URL}/v1/signup`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username: "Admin",
          mobileNumber: mobileNumber,
          otp: enteredOtp.join(""),
          userType: "Admin",
        }),
      });

      const data = await response.json();
      console.log("Signup Response:", data);

      if (!response.ok) {
        setError("Something went wrong. Please try again.");
        throw new Error("Something went wrong. Please try again.");
      }

      if (response.ok && data.status == false) {
        if (data.message?.includes("already registered")) {
          navigation.navigate("Dashboard");
          return;
        }
        setError(data.message);
        throw new Error(data.message);
      }

      navigation.navigate("Dashboard");
    } catch (error) {
      console.error("Error during signup:", error);
    }
  };



  const handleSubmit = async () => {
    if (isFormValid) {
      setLoading(true);
      try {
        const response = await fetch(`${BASE_URL}/v1/request-signup-otp?mobileNumber=${mobileNumber}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" }
        });

        if (!response.ok) {
          setError("Something went wrong please try again.");
          throw new Error("Something went wrong please try again.");
        }
        const data = await response.json();

        console.log("OTP API Response:", data);
        // Show OTP screen if request was successful
        if (response.ok && data.status == false) {
          setError(data.message);
          throw new Error(data.message);
        }
        setOtpScreen(true);
        setTimer(60); // reset countdown
        setOtp(["", "", "", ""]);
        setError(""); // clear previous errors

      } catch (error) {
        console.error("Error requesting OTP:", error);
        //  alert("Something went wrong while sending OTP. Please try again.");
      } finally {
        setLoading(false); // hide loader
      }
    }
  };

  // validation: username not empty && mobile number 10 digits
  const isFormValid =
    password.trim().length > 0 && /^[0-9]{10}$/.test(mobileNumber);

  useEffect(() => {
    if (timer > 0 && isOtpScreen) {
      const interval = setInterval(() => setTimer(timer - 1), 1000);
      return () => clearInterval(interval);
    }
  }, [timer, isOtpScreen]);

  const handleOtpChange = (text: string, index: number) => {
    const onlyDigits = text.replace(/[^\d]/g, "");
    const newOtp = [...otp];

    // Paste multiple digits
    if (onlyDigits.length > 1) {
      for (let i = 0; i < onlyDigits.length && index + i < otp.length; i++) {
        newOtp[index + i] = onlyDigits[i];
      }
      setOtp(newOtp);

      const nextIndex = Math.min(index + onlyDigits.length, otp.length - 1);
      if (nextIndex < otp.length - 1) {
        inputsRef.current[nextIndex + 1]?.focus();
      } else {
        Keyboard.dismiss();
        handleSignupWithOtp(newOtp); // 👈 use latest values
      }
      return;
    }

    newOtp[index] = onlyDigits;
    setOtp(newOtp);

    if (onlyDigits && index < otp.length - 1) {
      inputsRef.current[index + 1]?.focus();
    } else if (index === otp.length - 1 && onlyDigits) {
      Keyboard.dismiss();
      handleSignupWithOtp(newOtp); // 👈 use latest values
    }
  };


  const handleKeyPress = (
    e: NativeSyntheticEvent<TextInputKeyPressEventData>,
    index: number
  ) => {
    if (e.nativeEvent.key === "Backspace" && !otp[index] && index > 0) {
      inputsRef.current[index - 1]?.focus();
      const newOtp = [...otp];
      newOtp[index - 1] = "";
      setOtp(newOtp);
    }
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 40 : 0}
    >
      <ScrollView
        contentContainerStyle={styles.container}
        keyboardShouldPersistTaps="handled"
      >
        <StatusBar backgroundColor="#225663" barStyle="light-content" />

        <View style={styles.topSection}></View>

        {isOtpScreen ? (
          <View style={styles.bottomSheet}>
            <TouchableOpacity
              style={styles.backButton}
              onPress={() => setOtpScreen(false)}
              hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            >
              <Image
                source={require("./../assets/backarrow.png")}
                style={{ width: 24, height: 24, resizeMode: "contain" }}
              />
            </TouchableOpacity>
            <Text style={styles.brand}>ConnectThrive</Text>
            <Text style={styles.bottomTitle}>OTP Verification</Text>
            <Text style={styles.bottomSubtitle}>
              Enter OTP received on {mobileNumber}
            </Text>

            <View style={styles.otpInputs}>
              {otp.map((digit, index) => (
                <TextInput
                  key={index}
                  ref={(ref) => (inputsRef.current[index] = ref)}
                  style={styles.otpInput}
                  keyboardType="number-pad"
                  maxLength={1}
                  value={digit}
                  onChangeText={(value) => handleOtpChange(value, index)}
                  onKeyPress={(e) => handleKeyPress(e, index)}
                  autoFocus={index === 0}
                  returnKeyType={index === otp.length - 1 ? "done" : "next"}
                  textContentType="oneTimeCode"
                  autoComplete="one-time-code"
                />
              ))}
            </View>

            {/* Error message */}
            {error ? <Text style={styles.error}>{error}</Text> : null}

            <Text style={styles.resend}>
              Resend OTP in 00:{timer < 10 ? `0${timer}` : timer}
            </Text>
          </View>
        ) : (
          <View style={styles.bottomSheet}>
            <Text style={styles.brand}>ConnectThrive</Text>
            <Text style={styles.bottomTitle}>Login or Signup</Text>



            <View style={styles.inputContainer}>
              <Text style={styles.countryCode}>+91</Text>
              <TextInput
                placeholder="Enter Mobile Number"
                keyboardType="number-pad"
                style={styles.input}
                value={mobileNumber}
                onChangeText={setMobileNumber}
                maxLength={10}
              />
            </View>

            <View style={styles.inputContainer}>
              <TextInput
                placeholder="Enter password"
                style={styles.input}
                value={password}
                onChangeText={setPassword}
              />
            </View>

            <TouchableOpacity
              style={[
                styles.otpButton,
                { backgroundColor: isFormValid ? "#225663" : "#ccc" },
              ]}
              onPress={handleSubmit}
              disabled={!isFormValid || loading} // disable while loading
            >
              {loading ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.otpText}>GET OTP</Text>
              )}
            </TouchableOpacity>

          </View>
        )}
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

export default LoginScreen;

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: '#225663',
    justifyContent: 'space-between',
  },
  skip: {
    position: 'absolute',
    right: 20,
    top: 20,
    color: '#fff',
    fontWeight: '600',
  },
  topSection: {
    paddingTop: 60,
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 26,
    color: '#fff',
    fontWeight: 'bold',
    marginBottom: 10,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#fff',
    textAlign: 'center',
    marginBottom: 20,
  },
  highlight: {
    color: '#FFE600',
    fontWeight: 'bold',
  },
  bottomSheet: {
    backgroundColor: 'white',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 20,
    paddingBottom: 10, // Keep this small
  },
  brand: {
    fontSize: 20,
    fontWeight: '600',
    color: '#225663',
    textAlign: 'center',
    marginBottom: 6,
  },
  bottomTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
  },
  bottomSubtitle: {
    fontSize: 13,
    textAlign: 'center',
    color: '#999',
    marginBottom: 20,
  },
  inputContainer: {
    flexDirection: 'row',
    backgroundColor: '#F3F3F3',
    borderRadius: 10,
    paddingHorizontal: 15,
    alignItems: 'center',
    height: 45,
    marginBottom: 16,
  },
  countryCode: {
    marginRight: 10,
    fontSize: 16,
    color: '#000',
  },
  input: {
    flex: 1,
    fontSize: 16,
  },
  otpButton: {
    backgroundColor: '#225663',
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
  },
  otpText: {
    color: '#fff',
    fontWeight: 'bold',
  },
  otpWrapper: {
    backgroundColor: "#fff",
    flex: 1,
    width: "100%",
    borderTopLeftRadius: 25,
    borderTopRightRadius: 25,
    alignItems: "center",
    paddingVertical: 30,
  },
  otpInputs: {
    flexDirection: "row",
    justifyContent: "center",
    marginVertical: 20,
  },
  otpInput: {
    width: 45,
    height: 50,
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    textAlign: "center",
    fontSize: 18,
    marginHorizontal: 5,
  },
  resend: {
    color: "#888",
    marginTop: 10,
    textAlign: "center",
  },
  terms: {
    marginTop: 20,
    color: "#666",
    fontSize: 12,
    textAlign: "center",
    width: "80%",
  },
  backButton: {
    position: "absolute",
    left: 20,
    top: 20,
    padding: 12, // 👈 extra padding around icon
    borderRadius: 30, // optional, makes touch area circular
  },
  backIcon: {
    width: 24,
    height: 24,
    resizeMode: "contain",
  },
  error: {
    color: 'red',
    textAlign: 'center',
    marginTop: 1,
  },
});
