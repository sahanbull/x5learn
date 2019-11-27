from os import system


markdown_lines = []

def write(text):
    markdown_lines.append(text)

def on_or_off(is_on):
    return 'ON' if is_on else 'OFF'


write('<style>')
write('hr{margin: 30px 0;}')
write('h1{font-size: 24px}')
write('</style>')
for index in range(40):
    pair_number = 'p'+str(index+1)
    topics = [ 'Climate change', 'Machine learning' ]
    if int(index/4)%2==1:
        topics = topics[::-1]
    start_with_cf = int(index/2)%2==0
    write('# X5Learn Lab Session')
    write('Thursday 28 November 2019 - Tokyo')
    write('## Instructions')
    write('Using one laptop per pair, please go to http://145.14.12.67:6001')
    write('## Login')
    write('Your pair number: ' + pair_number)
    write('You password: japan')

    write('___')
    write('## Activity 1: Concept maps')
    write('### Topic A')
    write(topics[0])
    write('When working on this topic, ensure that ContentFlow is switched ' + on_or_off(start_with_cf))
    write('### Topic B')
    write(topics[1])
    write('When working on this topic, ensure that ContentFlow is switched ' + on_or_off(not start_with_cf))

    write('***')
    write('## Questionnaire 1')
    write('https://bit.ly/2XRWyLC')

    write('___')
    write('## Activity 2: Creating a lecture')
    write('As a topic, please choose either:')
    write('- A personal perspective on '+topics[0])
    write('OR')
    write('- A personal perspective on '+topics[1])
    write('Aim to collect at least 3 video snippets.')
    write('The total duration should be between 5 and 10 minutes.')
    write('Please take 30 minutes for this task.')

    write('***')
    write('## Questionnaire 2')
    write('https://bit.ly/2OPDwBc')

    write('<p style="height: 400px; page-break-before: always"></p>')


system('rm -f handouts.md')

with open('handouts.md', 'a') as f:
    for line in markdown_lines:
        f.write(line+'\n\n')


system('rm -f handouts.html')
system('rm -f handouts.pdf')
system('pandoc -f markdown handouts.md > handouts.html')
system('xhtml2pdf handouts.html')
# system('open handouts.pdf')
