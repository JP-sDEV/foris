import { StyleSheet, ScrollView } from 'react-native';
import { ThemedView } from '@/components/ThemedView';
import { dummyFeed } from '@/assets/dummydata';
import FeedCard from '@/components/ui/cards/FeedCard';
import { Post } from '@/types/post';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';


export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  return (
    // <SafeAreaView style={styles.container}>
       <ScrollView
        contentContainerStyle={{
          paddingBottom: insets.bottom
        }}

        showsVerticalScrollIndicator={false}
        showsHorizontalScrollIndicator={false}
      >
        <ThemedView style={styles.stepContainer}>
          {dummyFeed.map((post: Post, index) => (
            <FeedCard
              key={index}
              avatarUri={post.user.avatarUri}
              username={post.user.username}
              imageUri={'imageUri' in post ? post.imageUri : undefined}
              caption={post.caption}
              timestamp={post.timestamp}
              postType={post.postType}
              comments={'comments' in post ? post.comments : []}
              liked={post.liked}
              likesCount={post.likesCount}
              status={'status' in post ? post.status : undefined}
              leagueName={'leagueName' in post ? post.leagueName : undefined}
            />
          ))}
        </ThemedView>
    </ScrollView>


    // </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  stepContainer: {
    gap: 8,
    marginBottom: 8,
    paddingHorizontal: 12,
  },
  container: {
    flex: 1,
    backgroundColor: '#fff', // or theme background
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 16, // optional extra padding
  },
});
