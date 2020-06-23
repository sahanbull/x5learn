from x5learn_server.db.database import db_session
from x5learn_server.models import Oer


frozen_search_results_for_lab_study_tasks = {'labstudypractice': 'http://hydro.ijs.si/v00c/c5/yvx7x6jwd7qc47ffb2f3ai3ifugsaaa4.mp4 http://hydro.ijs.si/v00c/e7/473jgitijoew72s3mtgmy5o7dhkumj24.mp4 http://hydro.ijs.si/v003/e0/4bfzctxbyzv2f2hjed2455yanmlnouef.mp4 http://hydro.ijs.si/v009/83/qnzdoujssp46oxquhe7tslkhxikvu5wx.mp4 http://hydro.ijs.si/v00a/63/mpklwd24fti34fzr3wtfqsrwri77fg2i.mp4 http://hydro.ijs.si/v007/34/gqbq6bnhtl6pwaljnek6sqqnyfcrnel5.mp4 http://hydro.ijs.si/v008/33/gnhrnv5qobskejatgldskttfsmngfllv.mp4 http://hydro.ijs.si/v00a/08/bag4cjsxvcbkr6p3bzwz3qwdlcv4qsgz.mp4 http://hydro.ijs.si/v007/a7/u6xkhhillx2hr66bc6mqu54u37aq5utm.mp4 http://hydro.ijs.si/v00a/91/sgcnz4wsbmueogxkztiahz2jekhi74w7.mp4 http://hydro.ijs.si/v007/5f/l5r55luzh64kb5syjbrpzmikykmnm3ji.mp4 http://hydro.ijs.si/v015/f9/7gh3dwpzrfpfvxnrl5fkaq4nedrqguh6.mp4 http://hydro.ijs.si/v00b/8c/rsctlkzcht24mvake5k3cyjkbtfvr22b.mp4 http://hydro.ijs.si/v007/96/szhjyzxwpjvy22qkjrm7noqltcjjln25.mp4',
    'labstudytask1': 'http://hydro.ijs.si/v008/08/bakpa2caof2ohfwqgxvl3gofbocmcbzj.mp4 http://hydro.ijs.si/v008/9d/txu2dyzlsezh7iafx5vyai5g4vqixfuy.mp4 http://hydro.ijs.si/v008/75/ought5kolrkwnngygm7rxxrszamiefue.mp4 http://hydro.ijs.si/v008/02/akxzem4rlkry7wwzqvssi2ejuetxep5u.mp4 http://hydro.ijs.si/v001/ac/vravpnsbp233h2ybmwckumgokgzm4vwp.mp4 http://hydro.ijs.si/v008/e7/44uqvva27btwhg6rw3sbz6mzctjhip5j.mp4 http://hydro.ijs.si/v008/c5/ywtfprlupux4t4fro4rnu2skwcwe74oj.mp4 http://hydro.ijs.si/v008/75/ovn72pqdnzkscewhy4lwfpgksy5xedcy.mp4 http://hydro.ijs.si/v001/46/i3fx77camctxek5oqnpt7hjfflfpezor.mp4 http://hydro.ijs.si/v007/ca/zis7pi4waym6upo6hoh3rsqenasyapjf.mp4 http://hydro.ijs.si/v014/ef/54fzqeubjpsxzayqqpiogxutezsszotl.mp4 http://hydro.ijs.si/v008/78/pb6mpfywjrb43tsi6eenjlpjqyz3ia5h.mp4 http://hydro.ijs.si/v008/0d/bxpc33yg6f4vu3vsuchfbnfiwlnhzqtq.mp4 http://hydro.ijs.si/v008/c0/ycyojbnt7weiki5z7i6tyafflhegc2jr.mp4 http://hydro.ijs.si/v00a/50/kadebmtgr26c24akmmekej5ywl4u3etd.mp4 http://hydro.ijs.si/v001/9f/t4v4y3glsc533lz5rawulpkvhq2x24t2.mp4 http://hydro.ijs.si/v008/63/mpcudsa4fnc34psi2i7s25ogxjtjl4yl.mp4 http://hydro.ijs.si/v00a/56/kzgnjo3p2eab2kwjeltpulhgjn37mmy6.mp4',
    'labstudytask2': 'http://hydro.ijs.si/v001/52/kkdcku4sgycwzxge5wwcvssrs5ioqe7t.mp4 http://hydro.ijs.si/v001/21/egtdgchisqpe2vwi6coudlqimierznik.mp4 http://hydro.ijs.si/v013/d2/2i7cmpxwt6qavrvfpjpal3xcnuperw5n.mp4 http://hydro.ijs.si/v005/aa/vkfvobzijwpg3abv4uacf6imcysgf4xn.mp4 http://hydro.ijs.si/v019/9a/tlsmr7i7ssoq7nvjsp7ysrhkobwdzwcy.mp4 http://hydro.ijs.si/v006/05/avn23jrmv37diwjdjko25ujlrlllcnjv.mp4 http://hydro.ijs.si/v00f/39/hgzhj7qssnd7scoa7su46q3ai6b7kojm.mp4 http://hydro.ijs.si/v008/3d/hweimazo7hk6aguwk4hwixvyzzh3c5q2.mp4 http://hydro.ijs.si/v00a/aa/vk46bmymzqeyvuyz7ffkecnrhlijfkrb.mp4 http://hydro.ijs.si/v002/b8/xb22r5jpyww62yumsgqtpuksamch5ato.mp4 http://hydro.ijs.si/v007/31/geqvoh5gj63er5ybrxpbiokqrgf34jdy.mp4 http://hydro.ijs.si/v00b/e9/5hzbdusud6dqrwclwfrkr57kfc6tkxf3.mp4 http://hydro.ijs.si/v00c/8c/rtk44jumygn4qcc6bawmbtf6v2n6c5ae.mp4 http://hydro.ijs.si/v00c/9f/t6y7yp622djrb2j3uoze3lfj6atwg3lc.mp4 http://hydro.ijs.si/v013/1b/do7fmq4plaxpsp73qdf4v6d5gvyphw33.mp4 http://hydro.ijs.si/v013/d9/3fnzhei7p4t4a3g3brss7u6vbv2epwlv.mp4 http://hydro.ijs.si/v008/7c/ptwafsubgvlnxpuno7vl7ovn54hvesl4.mp4 http://hydro.ijs.si/v005/07/a6yv4l2zercnhebokq6heooiskdhmcsk.mp4',
    'youtubestudy': 'https://www.youtube.com/watch?v=dYPwEyeyPLA https://www.youtube.com/watch?v=rrADVNo-MFA https://www.youtube.com/watch?v=rsBB8-gzRJo https://www.youtube.com/watch?v=AKKAVTyzw-8 https://www.youtube.com/watch?v=8IPCMq7_Eec https://www.youtube.com/watch?v=FGDDHvSybTg https://www.youtube.com/watch?v=YdedJNkAkVw https://www.youtube.com/watch?v=EWRk4S_63yw https://www.youtube.com/watch?v=jabvEu7aHn0 https://www.youtube.com/watch?v=45QfiAUHWaA https://www.youtube.com/watch?v=UqF6m1UVuQM https://www.youtube.com/watch?v=X9t-u87df3o https://www.youtube.com/watch?v=UcWsDwg1XwM https://www.youtube.com/watch?v=T_I-CUOc_bk https://www.youtube.com/watch?v=tBBJ2TSTa1Q https://www.youtube.com/watch?v=oo1ZZlvT2LQ https://www.youtube.com/watch?v=2qxY859dzzQ'}


def frozen_search_results_for_lab_study(task_name):
    results = frozen_search_results_for_lab_study_tasks[task_name]
    if isinstance(results, str):
        urls = results.split(' ')
        # get oers from the db
        oers = [oer for oer in Oer.query.filter(Oer.url.in_(urls)).all()]
        # sort to restore the original order, see https://stackoverflow.com/a/29368913/2237986
        results = [next(o for o in oers if o.url==url) for url in urls]
        # cache the results for next time
        frozen_search_results_for_lab_study_tasks[task_name] = results
    return [results, 1, 1]


def is_special_search_key_for_lab_study(text):
    return text in frozen_search_results_for_lab_study_tasks
