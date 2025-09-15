// components/ui/TopBar.tsx
import React from "react";
import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { TopBarProps } from "@/types/TopBarProps";

const TopBar: React.FC<TopBarProps> = ({ 
    title = "Plot",
    rightElement,
    leftElement,
    middleElement,
    onPressNotifications,
    onPressTitle }) => {
  return (
    <View style={styles.container}>
      {/* Left element */}
      <TouchableOpacity onPress={onPressTitle}>
        <Text style={styles.title}>{title}</Text>
      </TouchableOpacity>
      
      {/* Middle element */}
      <View style={styles.middleElement}>
        {middleElement ? middleElement : <></>}
      </View>
     

      {/* Right element */}
      <TouchableOpacity onPress={onPressNotifications}>
        <Ionicons name="notifications-outline" size={28} color="#000" />
      </TouchableOpacity>
    </View>
  );
};

export default TopBar;

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 16,
    paddingBottom: 16,
    backgroundColor: "#fff", // change if using dark theme
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: "#ddd",
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    color: "#000",
  },

  subtitle: {
    fontSize: 20,
    fontWeight: "400",
    color: "#000",
  },
  
  middleElement: {
    paddingHorizontal: 10,
  }
});
