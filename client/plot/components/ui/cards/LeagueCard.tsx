// import React, { useCallback, useState } from "react";
// import {
//   View,
//   Text,
//   Image,
//   TouchableOpacity,
//   StyleSheet,
//   Dimensions,
//   useColorScheme,
// } from "react-native";

// type Comment = { id: string; user: string; text: string };

// export type LeagueCardProps = {
//   avatarUri?: string;
//   username: string;
//   liked?: boolean;
//   likesCount?: number;
//   caption?: string;
//   comments?: Comment[];
//   timestamp?: string;
//   points?: number;
//   leagueName?: string;
//   status?: string;
//   onLike?: () => void;
//   onComment?: () => void;
// };


// export default function LeagueCard({
//   avatarUri,
//   username,
//   liked: likedProp = false,
//   likesCount: likesCountProp = 0,
//   caption,
//   comments = [],
//   timestamp,
//   points = 0,
//   leagueName = "Test League",
//   status = "In Progress",
//   onLike,
//   onComment,
// }: LeagueCardProps) {
//   const [liked, setLiked] = useState<boolean>(likedProp);
//   const [likesCount, setLikesCount] = useState<number>(likesCountProp);
//   const colorScheme = useColorScheme();
//   const isDark = colorScheme === 'dark';

//   const toggleLike = useCallback(() => {
//     const next = !liked;
//     setLiked(next);
//     setLikesCount((c) => c + (next ? 1 : -1));
//     onLike?.();
//   }, [liked, onLike]);

//   return (
//     <View style={styles.card}>
//       {/* Header */}
//       <View style={styles.header}>
//         <Image
//           source={avatarUri ? { uri: avatarUri } : require("@/assets/images/icon.png")}
//           style={styles.avatar}
//         />
//         <View style={styles.userInfo}>
//           <Text style={styles.username}>{username}</Text>
//         <Text style={styles.timestamp}>{leagueName}</Text>
//           {timestamp && <Text style={styles.timestamp}>{timestamp}</Text>}
          
//         </View>
//         <View style={[styles.leagueBox, { backgroundColor: isDark ? '#fff' : '#111' }]}>
//           <Text style={[styles.leagueText, { color: isDark ? '#111' : '#fff' }]}>League</Text>
//         </View>
//       </View>

//       {/* Caption */}
//       {caption && (
//         <Text style={styles.captionText} numberOfLines={2} ellipsizeMode="tail">
//           {caption}
//         </Text>
//       )}

//       {/* Action Row Below Caption */}
//       <View style={styles.actionsRow}>
//         <TouchableOpacity onPress={toggleLike} style={styles.iconBtn}>
//           <Text style={styles.statEmoji}>{liked ? '👍' : '👍'}</Text>
//           <Text style={styles.statText}>{likesCount}</Text>
//         </TouchableOpacity>
//         <TouchableOpacity onPress={onComment} style={styles.iconBtn}>
//           <Text style={styles.statEmoji}>💬</Text>
//           <Text style={styles.statText}>{comments.length}</Text>
//         </TouchableOpacity>
//       </View>
//     </View>
//   );
// }

// const styles = StyleSheet.create({
//   card: {
//     backgroundColor: '#fff',
//     borderRadius: 12,
//     borderWidth: 1,
//     borderColor: '#e6e6e6',
//     marginBottom: 16,
//     overflow: 'hidden',
//     elevation: 1,
//   },
//   header: {
//     flexDirection: 'row',
//     alignItems: 'center',
//     padding: 12,
//     justifyContent: 'space-between',
//   },
//   avatar: {
//     width: 40,
//     height: 40,
//     borderRadius: 20,
//     backgroundColor: '#ddd',
//   },
//   userInfo: {
//     marginLeft: 10,
//     flex: 1,
//   },
//   username: {
//     fontWeight: '700',
//     fontSize: 16,
//   },
//   timestamp: {
//     color: '#999',
//     fontSize: 12,
//   },
//   leagueBox: {
//     paddingHorizontal: 10,
//     paddingVertical: 4,
//     borderRadius: 12,
//   },
//   leagueText: {
//     fontWeight: '600',
//     fontSize: 14,
//   },
//   captionText: {
//     paddingHorizontal: 12,
//     paddingVertical: 8,
//     fontSize: 14,
//     color: '#111',
//   },
//   actionsRow: {
//     flexDirection: 'row',
//     justifyContent: 'space-around',
//     alignItems: 'center',
//     paddingVertical: 8,
//   },
//   iconBtn: {
//     flexDirection: 'row',
//     alignItems: 'center',
//   },
//   statEmoji: {
//     fontSize: 20,
//     marginRight: 6,
//   },
//   statText: {
//     fontWeight: '600',
//   },
// });
