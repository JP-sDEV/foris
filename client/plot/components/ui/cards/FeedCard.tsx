import React, { useCallback, useState } from "react";
import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  useColorScheme
} from "react-native";

type Comment = { id: string; user: string; text: string };

export type PostType = 
  | "challenge"
  | "league"
  | "update"
  | "announcement";


export type FeedCardProps = {
  avatarUri?: string;
  username: string;
  imageUri?: string;
  caption?: string;
  timestamp?: string;
  postType: PostType;
  liked?: boolean;
  likesCount?: number;
  //   Exclusive properties for challenges  
  comments?: Comment[];
  points?: number;
  status?: string;
  //   Exclusive properties for leagues  
  leagueName?: string;
  // Methods   
  onLike?: () => void;
  onComment?: () => void;
};

const { width } = Dimensions.get("window");
const IMAGE_HEIGHT = width * 0.6;

export default function FeedCard({
  avatarUri,
  username,
  imageUri,
  caption,
  timestamp,
  postType,
  //   Exclusive properties for challenges
  comments = [],
  liked: likedProp = false,
  likesCount: likesCountProp = 0,
  points = 0,
  status = "In Progress",
  //   Exclusive properties for leagues
  leagueName = "",
  onLike,
  onComment,
}: FeedCardProps) {
  const [liked, setLiked] = useState<boolean>(likedProp);
  const [likesCount, setLikesCount] = useState<number>(likesCountProp);
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  const toggleLike = useCallback(() => {
    const next = !liked;
    setLiked(next);
    setLikesCount((c) => c + (next ? 1 : -1));
    onLike?.();
  }, [liked, onLike]);

  return (
    <View style={styles.card}>
      {/* Header */}
      <View style={styles.header}>
        <Image
          source={avatarUri ? { uri: avatarUri } : require("@/assets/images/icon.png")}
          style={styles.avatar}
        />
        <View style={styles.userInfo}>
          <Text style={styles.username}>{username}</Text>
          {timestamp && <Text style={styles.timestamp}>{timestamp}</Text>}
        </View>
        <View style={styles.pointsStatus}>
            {postType === "challenge" && 
            (<View>
                <Text style={styles.pointsText}>{points} pts</Text>
                    <View style={styles.statusBox}>
                        <Text style={styles.statusText}>{status}</Text>
                    </View>
            </View>
            )}
          {postType === "league" && leagueName.trim() && (
             <View style={[styles.leagueBox, { backgroundColor: isDark ? '#fff' : '#111' }]}>
                <Text style={[styles.leagueText, { color: isDark ? '#111' : '#fff' }]}>{leagueName}</Text>
              </View>
          )}
        </View>
      </View>

      {/* Image */}
      {imageUri && <Image source={{ uri: imageUri }} style={styles.postImage} />}

      {/* Caption */}
      {caption && (
        <Text style={styles.captionText} numberOfLines={2} ellipsizeMode="tail">
          {caption}
        </Text>
      )}

      {/* Action Row Below Caption */}
      <View style={styles.actionsRow}>
        <TouchableOpacity onPress={toggleLike} style={styles.iconBtn}>
          <Text style={styles.statEmoji}>{liked ? '👍' : '👍'}</Text>
          <Text style={styles.statText}>{likesCount}</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={onComment} style={styles.iconBtn}>
          <Text style={styles.statEmoji}>💬</Text>
          <Text style={styles.statText}>{comments.length}</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#e6e6e6',
    marginBottom: 16,
    overflow: 'hidden',
    elevation: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    justifyContent: 'space-between',
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#ddd',
  },
  userInfo: {
    marginLeft: 10,
    flex: 1,
  },
  username: {
    fontWeight: '700',
    fontSize: 16,
  },
  timestamp: {
    color: '#999',
    fontSize: 12,
  },
  pointsStatus: {
    alignItems: 'flex-end',
  },
  pointsText: {
    fontWeight: '600',
    fontSize: 14,
  },
  statusBox: {
    backgroundColor: '#FFA500',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
    marginTop: 4,
  },
  statusText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 12,
  },
  postImage: {
    width: '100%',
    height: IMAGE_HEIGHT,
    backgroundColor: '#f2f2f2',
  },
  captionText: {
    paddingHorizontal: 12,
    paddingVertical: 12,
    fontSize: 14,
    color: '#111',
  },
  actionsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    paddingVertical: 8,
  },
  iconBtn: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statEmoji: {
    fontSize: 20,
    marginRight: 6,
  },
  statText: {
    fontWeight: '600',
  },

    leagueBox: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  leagueText: {
    fontWeight: '600',
    fontSize: 14,
  },
});
