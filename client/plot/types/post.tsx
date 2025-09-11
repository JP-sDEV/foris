// types/post.ts
export type User = {
  avatarUri: string;
  username: string;
};

export type Comment = {
  id: string;
  user: string;
  text: string;
};

export type ChallengePost = {
  user: User;
  imageUri?: string;
  caption: string;
  timestamp: string;
  postType: "challenge";
  comments: Comment[];
  liked: boolean;
  likesCount: number;
  status: string;
};

export type LeaguePost = {
  user: User;
  caption: string;
  timestamp: string;
  postType: "league";
  liked: boolean;
  likesCount: number;
  leagueName: string;
  imageUri?: string;
};


export type Post = ChallengePost | LeaguePost;
