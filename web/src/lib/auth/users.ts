/**
 * 사용자 인메모리 저장소 (MVP)
 * 소셜 로그인 시 확인/생성 후 JWT sub로 사용
 */

export type AuthProvider = "google" | "kakao" | "apple";

export interface User {
  id: string;
  provider: AuthProvider;
  providerId: string;
  email?: string;
  displayName?: string;
  profileImage?: string;
  createdAt: string; // ISO
  lastLoginAt: string; // ISO
}

const usersById = new Map<string, User>();
const usersByProvider = new Map<string, string>(); // key: `${provider}:${providerId}` -> userId

function nextId(): string {
  return `user_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
}

/** provider + providerId로 사용자 찾기 또는 생성 */
export function findOrCreateUser(params: {
  provider: AuthProvider;
  providerId: string;
  email?: string;
  displayName?: string;
  profileImage?: string;
}): User {
  const key = `${params.provider}:${params.providerId}`;
  const existingId = usersByProvider.get(key);
  if (existingId) {
    const user = usersById.get(existingId);
    if (user) {
      user.lastLoginAt = new Date().toISOString();
      user.email = params.email ?? user.email;
      user.displayName = params.displayName ?? user.displayName;
      user.profileImage = params.profileImage ?? user.profileImage;
      return { ...user };
    }
  }

  const now = new Date().toISOString();
  const user: User = {
    id: nextId(),
    provider: params.provider,
    providerId: params.providerId,
    email: params.email,
    displayName: params.displayName,
    profileImage: params.profileImage,
    createdAt: now,
    lastLoginAt: now,
  };
  usersById.set(user.id, user);
  usersByProvider.set(key, user.id);
  return user;
}

/** userId로 사용자 조회 */
export function getUserById(userId: string): User | null {
  return usersById.get(userId) ?? null;
}
