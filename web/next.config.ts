import type { NextConfig } from "next";
import path from "node:path";
import fs from "node:fs";
import { config as loadEnv } from "dotenv";

const cwd = process.cwd();
for (const p of [path.join(cwd, ".env"), path.join(cwd, "..", ".env")]) {
  if (fs.existsSync(p)) {
    loadEnv({ path: p });
    break;
  }
}

const nextConfig: NextConfig = {
  output: "standalone",
};

export default nextConfig;
