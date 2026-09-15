#!/usr/bin/env python3
"""Build static, localized App Store support pages. No network or deployment."""
from pathlib import Path
import json
from html import escape as e
ROOT=Path(__file__).resolve().parents[1]
D=json.loads((ROOT/'Docs/AppStore/site-locales.json').read_text())
NAMES={'en':'English','fr':'Français','es':'Español','ja':'日本語','zh':'中文','ko':'한국어','ru':'Русский','de':'Deutsch','ar':'العربية','it':'Italiano','pt':'Português'}
assert set(D)==set(NAMES)
OUT=ROOT/'Docs/AppStore/site/NATURaL'
for lang,t in D.items():
 assert len(t)==36 and all(t),lang
 base='/NATURaL/'+('' if lang=='en' else lang+'/')
 nav=t[0].split('|')
 for section in ['', 'privacy', 'support']:
  url=base+(section+'/' if section else '')
  title={ '':t[2].replace('|',' '),'privacy':t[17],'support':t[29]}[section]
  options=''.join(f'<option value="{code}"'+(' selected' if lang==code else '')+f'>{name}</option>' for code,name in NAMES.items())
  alternates=''.join(f'<link rel="alternate" hreflang="{code}" href="https://thebonhomme.com/NATURaL/'+('' if code=='en' else code+'/')+(section+'/' if section else '')+'">' for code in D)
  if not section:
   headline=t[2].split('|')
   body=f'<section class="hero"><div><p class="eyebrow">NATURaL · {e(t[1])}</p><h1>{e(headline[0])}<br><em>{e(headline[1])}</em></h1><p class="lead">{e(t[3])}</p><a class="button" href="#practice">{e(t[4])} ↓</a><p class="quiet">{e(t[5])}<br>{e(t[6])}</p></div><img src="/NATURaL/bloom.png" width="1024" height="1024" alt="NATURaL"></section><section class="rule" id="practice"><p class="eyebrow">{e(t[7])}</p><h2 class="intro">{e(t[8])}</h2><div class="columns">'+''.join(f'<div><span class="number">0{i+1}</span><h3>{e(t[9+i*2])}</h3><p>{e(t[10+i*2])}</p></div>' for i in range(3))+f'</div></section><section class="rule"><h2>{e(t[15])}</h2><p class="lead">{e(t[16])}</p><a class="button" href="{base}privacy/">{e(t[17])}</a><a href="{base}support/">{e(nav[1])} →</a><p class="quiet">iOS / iPadOS 18+ · watchOS 10+</p></section>'
  elif section=='privacy':
   body=f'<article class="article"><h1>{e(t[17])}</h1><p class="meta">{e(t[18])}</p>'+''.join(f'<h2>{e(t[i])}</h2><p>{e(t[i+1])}</p>' for i in [19,21,23,25,27])+f'<h2>{e(t[15])}</h2><p>{e(t[16])}</p><p><a href="https://www.apple.com/legal/privacy/">Apple</a> · <a href="https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement">GitHub</a></p><a href="mailto:lp@thebonhomme.com">lp@thebonhomme.com</a></article>'
  else:
   body=f'<article class="article"><h1>{e(t[29])}</h1><p class="note">{e(t[6])}</p>'+''.join(f'<h2>{e(t[i])}</h2><p>{e(t[i+1])}</p>' for i in [30,32,34])+f'<a class="button" href="mailto:lp@thebonhomme.com?subject=NATURaL%20support">{e(nav[5])}</a><p><a href="{base}privacy/">{e(t[17])} →</a></p></article>'
  out=OUT/('' if lang=='en' else lang)/section/'index.html';out.parent.mkdir(parents=True,exist_ok=True)
  out.write_text(f'''<!doctype html>
<html lang="{lang}" dir="{'rtl' if lang=='ar' else 'ltr'}" data-section="{section}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="color-scheme" content="dark light"><title>{e(title)} · NATURaL</title><meta name="description" content="{e(t[3] if not section else title+' — '+t[5])}"><link rel="canonical" href="https://thebonhomme.com{url}">{alternates}<link rel="alternate" hreflang="x-default" href="https://thebonhomme.com/NATURaL/{section+'/' if section else ''}"><meta property="og:title" content="{e(title)} · NATURaL"><meta property="og:image" content="https://thebonhomme.com/NATURaL/bloom.png"><meta property="og:url" content="https://thebonhomme.com{url}"><link rel="icon" href="/NATURaL/bloom.png"><link rel="stylesheet" href="/tokens.css"><link rel="stylesheet" href="/theme.css"><link rel="stylesheet" href="/NATURaL/style.css"><script src="/theme.js"></script><script defer src="/NATURaL/language.js"></script></head><body><a class="skip" href="#main">{e(nav[4])}</a><header><a class="brand" dir="ltr" href="/">le bonhomme<span>pharma.</span></a><nav aria-label="NATURaL"><a href="{base}">{e(nav[0])}</a><a href="{base}support/">{e(nav[1])}</a><a href="{base}privacy/">{e(nav[2])}</a><label class="language-label"><span>{e(nav[3])}</span><select id="language" aria-label="{e(nav[3])}">{options}</select></label><span data-theme-mount></span></nav></header><main id="main">{body}<noscript><nav aria-label="{e(nav[3])}">{' '.join(f'<a href="/NATURaL/{code+"/" if code!="en" else ""}{section+"/" if section else ""}">{name}</a>' for code,name in NAMES.items())}</nav></noscript></main><footer><span dir="ltr">Le Bonhomme Pharma.<br>Montréal, Québec.</span><div class="footer-links"><a href="{base}support/">{e(nav[1])}</a><a href="{base}privacy/">{e(t[17])}</a><a href="mailto:lp@thebonhomme.com">{e(nav[5])}</a></div></footer></body></html>''')
print(f'Built {len(D)*3} pages in {len(D)} languages.')
