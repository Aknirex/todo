export async function openDatabase(name: string, version: number): Promise<any> {
  return new Promise((resolve, reject) => {
    const db = (uni as any).openDatabase({
      name,
      version,
      success: () => resolve(db),
      fail: (err: any) => reject(err)
    })
  })
}
