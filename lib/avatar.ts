// Mirrors SOCIETY/Services/DiceBearURLBuilder.swift — see that file for the
// rationale (PNG output is rate/size-limited, request 256 and let the client
// upscale, swap the style here if the design changes).

const DICEBEAR_API_VERSION = "9.x";
const DEFAULT_STYLE = "notionists";

export function buildDiceBearPngUrl(seed: string, size = 256, style = DEFAULT_STYLE): string {
  const params = new URLSearchParams({ seed, size: String(size) });
  return `https://api.dicebear.com/${DICEBEAR_API_VERSION}/${style}/png?${params.toString()}`;
}
