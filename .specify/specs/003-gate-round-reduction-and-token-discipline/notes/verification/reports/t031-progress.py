from pathlib import Path
from datetime import datetime, timezone
s = Path('.specify/specs/003-gate-round-reduction-and-token-discipline')
r = s / 'notes/verification/reports'
print(datetime.now(timezone.utc).isoformat(timespec='seconds'))
f = s / 'notes/verification/floors/.floor.NbXfe5/commands.nul'
if f.exists():
    a = f.read_bytes().decode().split('\0')[:-1]
    rows = [a[i:i+6] for i in range(0, len(a), 6)]
    print('records=',len(rows),'executed=',sum(x[5]=='0' for x in rows),'reuse=',sum(x[5]=='1' for x in rows))
    if rows: print('last=', rows[-1][0])
for p in (s/'notes').rglob('.capture.*'):
    if (p/'argv.nul').exists(): print('active=', (p/'argv.nul').read_bytes().replace(b'\0',b' ').decode())
    if (p/'output.log').exists(): print('\n'.join((p/'output.log').read_text().splitlines()[-3:]))
print('floor exit=', (r/'t031-floor-1.rc').read_text().strip() if (r/'t031-floor-1.rc').exists() else 'pending')
if (r/'t031-floor-1.log').exists(): print((r/'t031-floor-1.log').read_text()[-1000:])
