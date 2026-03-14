import { NextResponse } from "next/server";
import { getEnvDebug } from "@/lib/security/env";

/** 개발 모드에서만 AI 키 로드 상태 확인. 프로덕션에서는 404 */
export async function GET() {
  if (process.env.NODE_ENV !== "development") {
    return NextResponse.json({ error: "Not available" }, { status: 404 });
  }
  const debug = getEnvDebug();
  return NextResponse.json(debug);
}
