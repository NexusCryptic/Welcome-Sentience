#!/usr/bin/env python3
"""Build A Living System from its append-only JSONL source ledger."""
from __future__ import annotations
import hashlib, json, os, re, shutil, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "living-system"
LEDGER = BASE / "content" / "blocks.jsonl"
TEX = BASE / "manuscript" / "main.tex"
GENERATED = BASE / "manuscript" / "generated"
OUTPUT = BASE / "dist"
PDF = OUTPUT / "A-Living-System.pdf"
SAFE_MATH_COMMANDS = {"theta","Delta","sqrt","frac","sum","prod","mathbb","mathrm","operatorname","cdot","times","leq","geq","in","notin","forall","exists","mod","boxed","left","right","pi","varphi","alpha","beta","gamma","lambda","mu","sigma","tau","phi","omega","partial","nabla","log","exp","min","max"}

def require(command: str) -> str:
    path = shutil.which(command)
    if not path:
        raise RuntimeError(f"Required build tool not found on PATH: {command}")
    return path

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def read_blocks():
    blocks=[]
    for line_no,line in enumerate(LEDGER.read_text(encoding="utf-8").splitlines(),1):
        if not line.strip(): continue
        try: block=json.loads(line)
        except json.JSONDecodeError as exc: raise ValueError(f"{LEDGER}:{line_no}: invalid JSON: {exc}") from exc
        required={"id","sequence","kind","title","content"}
        missing=required-set(block)
        if missing: raise ValueError(f"{LEDGER}:{line_no}: missing {sorted(missing)}")
        if block["kind"] not in {"markdown","math"}: raise ValueError(f"{LEDGER}:{line_no}: unsupported block kind {block['kind']!r}")
        if not isinstance(block["id"],str) or not block["id"].strip(): raise ValueError(f"{LEDGER}:{line_no}: blank block id")
        if not isinstance(block["sequence"],int) or block["sequence"] < 1: raise ValueError(f"{LEDGER}:{line_no}: sequence must be a positive integer")
        if not isinstance(block["title"],str) or not isinstance(block["content"],str): raise ValueError(f"{LEDGER}:{line_no}: title/content must be strings")
        if block["kind"]=="math":
            commands=set(re.findall(r"\\([A-Za-z]+)",block["content"]))
            unsafe=commands-SAFE_MATH_COMMANDS
            if unsafe: raise ValueError(f"{LEDGER}:{line_no}: unapproved LaTeX math commands: {sorted(unsafe)}")
            if re.search(r"[%]|\\(input|include|write|openout|read|catcode|csname|def|newcommand|usepackage)",block["content"]):
                raise ValueError(f"{LEDGER}:{line_no}: unsafe TeX control sequence in math block")
        for source in block.get("sources",[]):
            parsed=urlparse(source.get("url",""))
            if parsed.scheme!="https" or not parsed.netloc: raise ValueError(f"{LEDGER}:{line_no}: source URLs must be absolute HTTPS URLs")
        blocks.append(block)
    ids=[b["id"] for b in blocks]; seq=[b["sequence"] for b in blocks]
    if len(ids)!=len(set(ids)): raise ValueError("Duplicate block IDs detected; refusing ambiguous lineage.")
    if seq!=sorted(seq) or len(seq)!=len(set(seq)): raise ValueError("Sequence values must be strictly increasing in ledger order.")
    return blocks

def tex_escape(value: str) -> str:
    table={"\\":r"\textbackslash{}","&":r"\&","%":r"\%","$":r"\$","#":r"\#","_":r"\_","{":r"\{","}":r"\}","~":r"\textasciitilde{}","^":r"\textasciicircum{}"}
    return "".join(table.get(ch,ch) for ch in str(value))

def pandoc_markdown(source: str) -> str:
    proc=subprocess.run([require("pandoc"),"-f","markdown-raw_html-raw_tex","-t","latex","--wrap=none"],
        input=source,text=True,capture_output=True,check=False)
    if proc.returncode: raise RuntimeError("Pandoc conversion failed: "+proc.stderr.strip())
    return proc.stdout

def make_body(blocks):
    out=[]
    for block in blocks:
        title=tex_escape(block["title"]); slug="block:"+str(block["id"])
        out.append("\\clearpage\n\\phantomsection\n\\section{"+title+"}\n\\label{"+tex_escape(slug)+"}\n")
        margin=block.get("margin","").strip()
        if margin: out.append("\\marginpar{\\raggedright\\scriptsize\\textbf{Margin}\\par "+tex_escape(margin)+"}\n")
        for term in block.get("index_terms",[]): out.append("\\index{"+tex_escape(term)+"}\n")
        if block["kind"]=="math": out.append("\\[\\displaystyle "+block["content"]+"\\]\n")
        else: out.append(pandoc_markdown(block["content"])+"\n")
        for source in block.get("sources",[]):
            url=source["url"]; label=tex_escape(source.get("label",url))
            out.append("\\smallskip\\noindent\\textit{Source:} \\href{"+url+"}{"+label+"}\\par\n")
        out.append("\\smallskip\\noindent\\textcolor{gray}{\\footnotesize Block "+tex_escape(block["id"])+" -- "+tex_escape(block.get("status","candidate"))+"}\\par\n")
    return "".join(out)

def attach_sources(pdf_path: Path, blocks):
    writer=PdfWriter(clone_from=str(pdf_path))
    writer.add_metadata({"/Title":"A Living System — Computational Publication","/Author":"The Architect / Nexus",
        "/Subject":"Versioned GAIA / NEXUS research and architecture publication",
        "/Keywords":"GAIA; NEXUS; LaTeX; HTMX 4; provenance; appendable publication"})
    attachments=[
        (BASE/"README.md","living-system-README.md"),(LEDGER,"blocks.jsonl"),(TEX,"main.tex"),
        (BASE/"manuscript"/"references.bib","references.bib"),
        (BASE/"editorial"/"index.html","editorial-canvas.html"),
        (BASE/"editorial"/"partials"/"research-ledger.html","research-ledger-fragment.html"),
        (ROOT/"research"/"ALPHAXIV_RESEARCH_LEDGER.md","ALPHAXIV_RESEARCH_LEDGER.md")]
    for source,name in attachments:
        if source.exists(): writer.add_attachment(name,source.read_bytes())
    writer.add_attachment("publication-blocks.json",json.dumps(blocks,ensure_ascii=False,indent=2).encode())
    temp=pdf_path.with_suffix(".attached.pdf")
    with temp.open("wb") as stream: writer.write(stream)
    temp.replace(pdf_path)

def main():
    require("pandoc"); require("pdflatex"); require("bibtex"); require("makeindex")
    if not LEDGER.exists() or not TEX.exists(): raise RuntimeError("Missing source ledger or LaTeX manuscript.")
    blocks=read_blocks(); GENERATED.mkdir(parents=True,exist_ok=True); OUTPUT.mkdir(parents=True,exist_ok=True)
    (GENERATED/"blocks.tex").write_text(make_body(blocks),encoding="utf-8")
    env=os.environ.copy(); command=[require("pdflatex"),"-interaction=nonstopmode","-halt-on-error","-output-directory",str(OUTPUT),"main.tex"]
    def run(args):
        proc=subprocess.run(args,cwd=TEX.parent,env=env,text=True,capture_output=True,check=False)
        if proc.returncode:
            log=OUTPUT/"main.log"; tail=log.read_text(errors="replace")[-5000:] if log.exists() else proc.stdout[-3000:]
            raise RuntimeError("Build command failed: "+ " ".join(args)+"\n"+tail)
    run(command)
    run([require("bibtex"),str(OUTPUT/"main")])
    idx=OUTPUT/"main.idx"
    if idx.exists(): run([require("makeindex"),str(idx)])
    run(command); run(command)
    built=OUTPUT/"main.pdf"
    if not built.exists(): raise RuntimeError("LaTeX completed without producing main.pdf")
    built.rename(PDF); attach_sources(PDF,blocks)
    reader=PdfReader(str(PDF))
    if not reader.pages: raise RuntimeError("Output PDF has no readable pages")
    manifest={"publication_id":"TDOC-LIVING-SYSTEM-COMP-PUB-0001","revision":"0.1.0+ledger-"+str(len(blocks)),
        "built_at":datetime.now(timezone.utc).isoformat(),"block_count":len(blocks),
        "ledger_sha256":digest(LEDGER.read_bytes()),"pdf_sha256":digest(PDF.read_bytes()),"pdf_bytes":PDF.stat().st_size,
        "page_count":len(reader.pages),"attachments":["blocks.jsonl","main.tex","references.bib","editorial-canvas.html","ALPHAXIV_RESEARCH_LEDGER.md"],
        "capabilities":{"latex_compile":"ACTIVE","bibtex":"ACTIVE","index_generation":"ACTIVE","pdf_attachments":"ACTIVE",
        "htmx_editorial_companion":"SOURCE_ATTACHED_BROWSER_EXECUTION_REQUIRED","pdf_embedded_htmx_execution":"UNSUPPORTED_BY_DESIGN"}}
    (OUTPUT/"build-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(manifest,indent=2)); print(f"PDF: {PDF}")

if __name__=="__main__":
    try: main()
    except Exception as exc:
        print(f"[BUILD ERROR] {exc}",file=sys.stderr); sys.exit(1)
