# Social Media API 

A GraphQL-based social media API built with NestJS, Prisma, and PostgreSQL. This API provides comprehensive functionality for user management, authentication, posts, comments, likes, and social features like following users.

## Features

- **User Management**: Create, update, and manage user profiles
- **OAuth Authentication**: Support for Google OAuth with JWT tokens
- **Posts & Content**: Create, read, update, and delete posts
- **Social Interactions**: Like posts, comment on posts, follow users
- **Media Support**: File upload and media management
- **Challenges & Leagues**: Gamification features with user challenges and leagues
- **GraphQL API**: Type-safe API with auto-generated schema

## Tech Stack

- **Framework**: NestJS
- **Database**: PostgreSQL with Prisma ORM
- **API**: GraphQL with Apollo Server
- **Authentication**: JWT with OAuth2 (Google)
- **Language**: TypeScript

## Prerequisites

- Node.js (v18 or higher)
- PostgreSQL database
- Docker (optional, for containerized setup)

## Installation

1. **Clone the repository and install dependencies:**
```bash
npm install
```

2. **Set up the database:**
```bash
# Start PostgreSQL with Docker
docker-compose up -d db

# Or use your local PostgreSQL instance
# Make sure it's running on localhost:5432
```

3. **Configure environment variables:**
```bash
# Copy the example environment file
cp .env.dev.local .env

# Update DATABASE_URL if needed
DATABASE_URL="postgresql://root:123@localhost:5432/nestjs?schema=public"
```

4. **Set up the database schema:**
```bash
# Generate Prisma client and run migrations
npx prisma generate
npx prisma migrate dev

# Seed the database with mock data (optional)
npm run db:populate
```

## Running the Application

```bash
# Development mode with OAuth mock server
npm run start:dev

# Production mode
npm run start:prod

# Debug mode
npm run start:debug
```

The API will be available at:
- **GraphQL Playground**: http://localhost:3000/api/graphql
- **API Endpoint**: http://localhost:3000/api

## Testing

```bash
# Unit tests
npm run test

# Integration tests
npm run test:e2e

# Test coverage
npm run test:cov

# Watch mode
npm run test:watch
```

## API Usage

### GraphQL Endpoint

The API uses GraphQL and is available at `/api/graphql`. You can explore the API using the GraphQL Playground at http://localhost:3000/api/graphql.

### Authentication

The API uses JWT tokens for authentication. To authenticate:

1. **Create an OAuth account:**
```graphql
mutation CreateAuth($input: CreateAuthInput!) {
  createAuth(createAuthInput: $input) {
    user {
      id
      name
      email
    }
    refreshToken
  }
}
```

Variables:
```json
{
  "input": {
    "email": "user@example.com",
    "name": "John Doe",
    "provider": "google",
    "providerUserId": "google-user-id",
    "idToken": "google-id-token"
  }
}
```

2. **Refresh tokens:**
```graphql
mutation RefreshToken($refreshToken: String!) {
  refreshToken(refreshToken: $refreshToken) {
    user {
      id
      name
      email
    }
    refreshToken
  }
}
```

### Core Operations

#### Users

**Get user by ID:**
```graphql
query GetUser($id: String!) {
  user(id: $id) {
    id
    name
    email
    bio
    oauthAccounts {
      provider
    }
  }
}
```

**Update user profile:**
```graphql
mutation UpdateUser($input: UpdateUserInput!) {
  updateUser(updateUserInput: $input) {
    id
    name
    email
    bio
    avatarUrl
  }
}
```

#### Posts

**Create a post:**
```graphql
mutation CreatePost($input: CreatePostInput!) {
  createPost(createPostInput: $input) {
    id
    title
    content
    authorId
  }
}
```

Variables:
```json
{
  "input": {
    "title": "My First Post",
    "content": "This is the content of my post",
    "authorId": "user-uuid-here"
  }
}
```

**Get user's posts:**
```graphql
query GetUserPosts($userId: String!) {
  userPosts(userId: $userId) {
    id
    title
    content
    authorId
  }
}
```

**Get single post:**
```graphql
query GetPost($id: String!) {
  post(id: $id) {
    id
    title
    content
    authorId
  }
}
```

#### Comments

**Create a comment:**
```graphql
mutation CreateComment($input: CreateCommentInput!) {
  createComment(createCommentInput: $input) {
    id
    content
    createdAt
    user {
      name
    }
    post {
      title
    }
  }
}
```

Variables:
```json
{
  "input": {
    "content": "Great post!",
    "postId": "post-uuid-here"
  }
}
```

#### Likes

**Like a post:**
```graphql
mutation CreateLike($input: CreateLikeInput!) {
  createLike(createLikeInput: $input) {
    userId
    postId
    user {
      name
    }
    post {
      title
    }
  }
}
```

Variables:
```json
{
  "input": {
    "postId": "post-uuid-here"
  }
}
```

**Remove a like:**
```graphql
mutation RemoveLike($id: String!) {
  removeLike(id: $id) {
    userId
    postId
  }
}
```

### Error Handling

The API returns standard GraphQL errors with descriptive messages:

```json
{
  "errors": [
    {
      "message": "Post not found",
      "extensions": {
        "code": "NOT_FOUND"
      }
    }
  ]
}
```

Common error types:
- `NOT_FOUND`: Resource doesn't exist
- `VALIDATION_ERROR`: Invalid input data
- `UNAUTHORIZED`: Authentication required
- `INTERNAL_SERVER_ERROR`: Server error

## Database Schema

The API uses the following main entities:

### User
- `id`: UUID primary key
- `name`: User's display name
- `email`: Unique email address
- `bio`: Optional user biography
- `avatarUrl`: Optional profile image URL
- `createdAt`: Account creation timestamp

### Post
- `id`: UUID primary key
- `title`: Post title
- `content`: Post content (optional)
- `authorId`: Reference to User
- `createdAt`: Post creation timestamp

### Comment
- `id`: UUID primary key
- `content`: Comment text
- `userId`: Reference to User
- `postId`: Reference to Post
- `createdAt`: Comment creation timestamp

### Like
- `userId`: Reference to User (composite key)
- `postId`: Reference to Post (composite key)

### OAuthAccount
- `id`: UUID primary key
- `provider`: OAuth provider (e.g., "google")
- `providerUserId`: Provider's user ID
- `userId`: Reference to User

## Development

### Project Structure

```
src/
├── auth/           # Authentication module
├── user/           # User management
├── post/           # Post operations
├── comment/        # Comment system
├── like/           # Like functionality
├── session/        # Session management
├── userfollow/     # Follow system
├── prisma/         # Database service
└── common/         # Shared utilities
```

### Adding New Features

1. Generate a new module:
```bash
nest generate module feature-name
nest generate service feature-name
nest generate resolver feature-name
```

2. Update the Prisma schema if needed:
```bash
# Edit prisma/schema.prisma
npx prisma migrate dev --name feature-name
npx prisma generate
```

3. Add the module to `app.module.ts`

### Code Style

The project uses:
- **ESLint** for linting
- **Prettier** for code formatting
- **Jest** for testing

Run formatting and linting:
```bash
npm run format
npm run lint
```

## Docker Support

Run the entire stack with Docker:

```bash
# Start database and OAuth mock server
docker-compose up -d

# The application runs on the host machine
npm run start:dev
```

Services:
- **PostgreSQL**: localhost:5432
- **OAuth Mock Server**: localhost:8080

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://root:123@localhost:5432/nestjs?schema=public` |
| `PORT` | Application port | `3000` |

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and add tests
4. Run tests: `npm run test`
5. Commit your changes: `git commit -am 'Add feature'`
6. Push to the branch: `git push origin feature-name`
7. Submit a pull request

## License

This project is licensed under the MIT License.
