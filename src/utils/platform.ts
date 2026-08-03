export type Platform = 'mp-weixin' | 'app' | 'h5'

export function getPlatform(): Platform {
  if (typeof wx !== 'undefined' && wx.getSystemInfoSync) {
    return 'mp-weixin'
  }
  if (typeof plus !== 'undefined') {
    return 'app'
  }
  return 'h5'
}

export function supportsAgentApi(): boolean {
  return getPlatform() === 'app'
}
