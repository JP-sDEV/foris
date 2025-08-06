import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { User } from '../user/entities/user.entity';
import {
  UserNotFoundException,
  SelfFollowException,
  DatabaseException,
} from './exceptions/userfollow.exceptions';
import { UserService } from '../user/user.service';

@Injectable()
export class UserfollowService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userService: UserService,
  ) {}

  /**
   * Validates that a user exists in the database
   * @param userId - The user ID to validate
   * @throws UserNotFoundException if user doesn't exist
   */
  async validateUserExists(userId: string): Promise<void> {
    try {
      const user = await this.userService.findOneById(userId);

      if (!user) {
        throw new UserNotFoundException(userId);
      }
    } catch (error) {
      if (error instanceof UserNotFoundException) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to validate user existence: ${error.message}`,
      );
    }
  }

  /**
   * Creates a follow relationship between two users
   * @param currentUserId - The user who wants to follow
   * @param targetUserId - The user to be followed
   * @returns Promise<boolean> - true if successful
   * @throws SelfFollowException if user tries to follow themselves
   * @throws UserNotFoundException if either user doesn't exist
   * @throws DatabaseException for database errors
   */
  async followUser(
    currentUserId: string,
    targetUserId: string,
  ): Promise<boolean> {
    try {
      // Prevent self-follow
      if (currentUserId === targetUserId) {
        throw new SelfFollowException();
      }

      // Validate both users exist
      await this.validateUserExists(currentUserId);
      await this.validateUserExists(targetUserId);

      // Check if already following (handle gracefully)
      const existingFollow = await this.prisma.userFollow.findUnique({
        where: {
          followId_followingId: {
            followId: currentUserId,
            followingId: targetUserId,
          },
        },
      });

      if (existingFollow) {
        // Already following - return true without error
        return true;
      }

      // Create follow relationship
      await this.prisma.userFollow.create({
        data: {
          followId: currentUserId,
          followingId: targetUserId,
        },
      });

      return true;
    } catch (error) {
      if (
        error instanceof SelfFollowException ||
        error instanceof UserNotFoundException
      ) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to create follow relationship: ${error.message}`,
      );
    }
  }

  /**
   * Removes a follow relationship between two users
   * @param currentUserId - The user who wants to unfollow
   * @param targetUserId - The user to be unfollowed
   * @returns Promise<boolean> - true if successful
   * @throws UserNotFoundException if either user doesn't exist
   * @throws DatabaseException for database errors
   */
  async unfollowUser(
    currentUserId: string,
    targetUserId: string,
  ): Promise<boolean> {
    try {
      // Validate both users exist
      await this.validateUserExists(currentUserId);
      await this.validateUserExists(targetUserId);

      // Delete follow relationship if it exists
      await this.prisma.userFollow.deleteMany({
        where: {
          followId: currentUserId,
          followingId: targetUserId,
        },
      });

      // Return true regardless of whether relationship existed
      return true;
    } catch (error) {
      if (error instanceof UserNotFoundException) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to remove follow relationship: ${error.message}`,
      );
    }
  }

  /**
   * Retrieves all users who follow the specified user
   * @param userId - The user ID to get followers for
   * @returns Promise<User[]> - Array of users who follow the specified user
   * @throws UserNotFoundException if user doesn't exist
   * @throws DatabaseException for database errors
   */
  async getFollowers(userId: string): Promise<User[]> {
    try {
      // Validate user exists
      await this.validateUserExists(userId);

      // Get followers with user details
      const followers = await this.prisma.userFollow.findMany({
        where: {
          followingId: userId,
        },
        include: {
          follower: {
            select: {
              id: true,
              name: true,
              email: true,
              bio: true,
              avatarUrl: true,
            },
          },
        },
      });

      return followers.map((follow) => follow.follower);
    } catch (error) {
      if (error instanceof UserNotFoundException) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to retrieve followers: ${error.message}`,
      );
    }
  }

  /**
   * Retrieves all users that the specified user follows
   * @param userId - The user ID to get following list for
   * @returns Promise<User[]> - Array of users that the specified user follows
   * @throws UserNotFoundException if user doesn't exist
   * @throws DatabaseException for database errors
   */
  async getFollowing(userId: string): Promise<User[]> {
    try {
      // Validate user exists
      await this.validateUserExists(userId);

      // Get following with user details
      const following = await this.prisma.userFollow.findMany({
        where: {
          followId: userId,
        },
        include: {
          following: {
            select: {
              id: true,
              name: true,
              email: true,
              bio: true,
              avatarUrl: true,
            },
          },
        },
      });

      return following.map((follow) => follow.following);
    } catch (error) {
      if (error instanceof UserNotFoundException) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to retrieve following list: ${error.message}`,
      );
    }
  }

  /**
   * Gets the count of followers for a user
   * @param userId - The user ID to get follower count for
   * @returns Promise<number> - Number of followers
   * @throws UserNotFoundException if user doesn't exist
   * @throws DatabaseException for database errors
   */
  async getFollowerCount(userId: string): Promise<number> {
    try {
      // Validate user exists
      await this.validateUserExists(userId);

      // Count followers
      const count = await this.prisma.userFollow.count({
        where: {
          followingId: userId,
        },
      });

      return count;
    } catch (error) {
      if (error instanceof UserNotFoundException) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to get follower count: ${error.message}`,
      );
    }
  }

  /**
   * Gets the count of users that a user follows
   * @param userId - The user ID to get following count for
   * @returns Promise<number> - Number of users being followed
   * @throws UserNotFoundException if user doesn't exist
   * @throws DatabaseException for database errors
   */
  async getFollowingCount(userId: string): Promise<number> {
    try {
      // Validate user exists
      await this.validateUserExists(userId);

      // Count following
      const count = await this.prisma.userFollow.count({
        where: {
          followId: userId,
        },
      });

      return count;
    } catch (error) {
      if (error instanceof UserNotFoundException) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to get following count: ${error.message}`,
      );
    }
  }

  /**
   * Checks if a user is following another user
   * @param currentUserId - The user who might be following
   * @param targetUserId - The user who might be followed
   * @returns Promise<boolean> - true if following, false otherwise
   * @throws UserNotFoundException if either user doesn't exist
   * @throws DatabaseException for database errors
   */
  async isFollowing(
    currentUserId: string,
    targetUserId: string,
  ): Promise<boolean> {
    try {
      // Validate both users exist
      await this.validateUserExists(currentUserId);
      await this.validateUserExists(targetUserId);

      // Check if follow relationship exists
      const follow = await this.prisma.userFollow.findUnique({
        where: {
          followId_followingId: {
            followId: currentUserId,
            followingId: targetUserId,
          },
        },
      });

      return !!follow;
    } catch (error) {
      if (error instanceof UserNotFoundException) {
        throw error;
      }
      throw new DatabaseException(
        `Failed to check follow status: ${error.message}`,
      );
    }
  }
}
