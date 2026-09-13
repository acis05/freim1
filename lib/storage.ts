import { mkdir,writeFile } from "fs/promises";
import path from "path";
import crypto from "crypto";
const root=process.env.STORAGE_DIR||path.join(process.cwd(),"storage","uploads");
export function getTenantStorageRoot(tenantId:string){return path.join(root,tenantId)}
export async function saveUploadDetailed(tenantId:string,file:File|null,prefix="file"){if(!file||file.size===0)return{url:null as string|null,hash:null as string|null};if(file.size>10*1024*1024)throw new Error("File maksimal 10 MB");const allowed=["image/jpeg","image/png","image/webp","application/pdf"];if(!allowed.includes(file.type))throw new Error("Format file harus JPG, PNG, WEBP, atau PDF");const dir=getTenantStorageRoot(tenantId);await mkdir(dir,{recursive:true});const bytes=Buffer.from(await file.arrayBuffer());const hash=crypto.createHash("sha256").update(bytes).digest("hex");const ext=path.extname(file.name).toLowerCase()||(file.type==="application/pdf"?".pdf":".jpg");const name=`${prefix}-${Date.now()}-${crypto.randomBytes(6).toString("hex")}${ext}`;await writeFile(path.join(dir,name),bytes);return{url:`/api/files/${tenantId}/${name}`,hash}}
export async function saveUpload(tenantId:string,file:File|null,prefix="file"){return(await saveUploadDetailed(tenantId,file,prefix)).url}
