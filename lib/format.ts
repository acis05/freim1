export function rupiah(v:unknown){return new Intl.NumberFormat("id-ID",{style:"currency",currency:"IDR",maximumFractionDigits:0}).format(Number(v??0))}
export function dateID(v:Date|string|null|undefined){return v?new Intl.DateTimeFormat("id-ID",{dateStyle:"medium"}).format(new Date(v)):"-"}
export function normalizeCode(v:string){return v.trim().toUpperCase().replace(/[^A-Z0-9-]/g,"").slice(0,20)}
export function slugify(v:string){return v.toLowerCase().trim().replace(/[^a-z0-9]+/g,"-").replace(/^-|-$/g,"").slice(0,40)}
