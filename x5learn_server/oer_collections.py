from x5learn_server.models import Oer

oer_collections = {'AlanTuringInstitute': {'channel': 'https://www.youtube.com/channel/UCcr5vuAH5TPlYox-QLj4ySw/videos',
  'title': 'Alan Turing Institute',
  'video_urls': ['https://www.youtube.com/watch?v=vDl5NVStQwU',
    'https://www.youtube.com/watch?v=mku33qVeNUY',
    'https://www.youtube.com/watch?v=TebxQ2P7feA',
    'https://www.youtube.com/watch?v=w8JuCSSXxJQ',
    'https://www.youtube.com/watch?v=hmfxAeSJVpo',
    'https://www.youtube.com/watch?v=38M3zUqH3D4',
    'https://www.youtube.com/watch?v=hrTNYKGzPOw',
    'https://www.youtube.com/watch?v=ZUsW_4GdEK8',
    'https://www.youtube.com/watch?v=LSTq6A5-q0E',
    'https://www.youtube.com/watch?v=Mg0fSuUspgY',
    'https://www.youtube.com/watch?v=E12_F4xeOHw',
    'https://www.youtube.com/watch?v=qBnGIJaVxGo',
    'https://www.youtube.com/watch?v=sUs70DshtWI',
    'https://www.youtube.com/watch?v=BQg-aG8J2DU',
    'https://www.youtube.com/watch?v=yqddYX05NQc',
    'https://www.youtube.com/watch?v=rzfITGipyeA',
    'https://www.youtube.com/watch?v=gNIWDvzsPho',
    'https://www.youtube.com/watch?v=xAhzQQ5Hc0A',
    'https://www.youtube.com/watch?v=2ovZnvVPiQ8',
    'https://www.youtube.com/watch?v=R8-3tnHWwiE',
    'https://www.youtube.com/watch?v=v-R-peYaTxs',
    'https://www.youtube.com/watch?v=vws4xF6gXmU',
    'https://www.youtube.com/watch?v=4NnIEDk96Pk',
    'https://www.youtube.com/watch?v=hpRa2fiLm_8',
    'https://www.youtube.com/watch?v=6v5zCblrCLw',
    'https://www.youtube.com/watch?v=5RTkhfVIW40',
    'https://www.youtube.com/watch?v=rUWzRF5mYNw',
    'https://www.youtube.com/watch?v=bnJyMdJAH7o',
    'https://www.youtube.com/watch?v=fbIDk479nRg',
    'https://www.youtube.com/watch?v=FdB92dTvIeg',
    'https://www.youtube.com/watch?v=AoGGx76WXnc',
    'https://www.youtube.com/watch?v=Jn6dsswXla0',
    'https://www.youtube.com/watch?v=6fshXFCX75M',
    'https://www.youtube.com/watch?v=srBhz7DL1kM',
    'https://www.youtube.com/watch?v=ANlZYZbQ-8M',
    'https://www.youtube.com/watch?v=bNu0eKWuOvM',
    'https://www.youtube.com/watch?v=SWyb74Bon34',
    'https://www.youtube.com/watch?v=L6CqqlILBCI',
    'https://www.youtube.com/watch?v=B8REHsG3chw',
    'https://www.youtube.com/watch?v=Gkk6XvJi6Qw',
    'https://www.youtube.com/watch?v=GlKyizqdGIY',
    'https://www.youtube.com/watch?v=_wuFBF_Cgm0',
    'https://www.youtube.com/watch?v=orUB2rh_yGc',
    'https://www.youtube.com/watch?v=da7PlzGh4to',
    'https://www.youtube.com/watch?v=Ymnbt8bIKMk',
    'https://www.youtube.com/watch?v=Y4F7UuBnqdk',
    'https://www.youtube.com/watch?v=iCCJki8reZU',
    'https://www.youtube.com/watch?v=nqfvr4pRB_o',
    'https://www.youtube.com/watch?v=xZrUZ2OVpZU',
    'https://www.youtube.com/watch?v=tIUvDGkgfwU',
    'https://www.youtube.com/watch?v=Pw4lM3ZPoZE',
    'https://www.youtube.com/watch?v=DwjmEZ6-Qy4',
    'https://www.youtube.com/watch?v=CClGs6o7Bs0',
    'https://www.youtube.com/watch?v=RrEdJDpskjo',
    'https://www.youtube.com/watch?v=2sH9JHTHE1A',
    'https://www.youtube.com/watch?v=j0fjrfWGhKQ',
    'https://www.youtube.com/watch?v=8EmFRbZAElM',
    'https://www.youtube.com/watch?v=JmgvQPOOmoI',
    'https://www.youtube.com/watch?v=hkI_CkYWeJM',
    'https://www.youtube.com/watch?v=nw9KjLBWf2o',
    'https://www.youtube.com/watch?v=-G09F856lU4',
    'https://www.youtube.com/watch?v=troT5opZt4I',
    'https://www.youtube.com/watch?v=YdZXCab6k0Q',
    'https://www.youtube.com/watch?v=O3dnYsGVgQU',
    'https://www.youtube.com/watch?v=poqpsiS1fuA',
    'https://www.youtube.com/watch?v=D-Jx9nRX1ec',
    'https://www.youtube.com/watch?v=WsPC_VMwXWA',
    'https://www.youtube.com/watch?v=FEbZdetm49g',
    'https://www.youtube.com/watch?v=W4LtKqCmUnk',
    'https://www.youtube.com/watch?v=y7ehrXZfIS0',
    'https://www.youtube.com/watch?v=REAOnqMtaVY',
    'https://www.youtube.com/watch?v=vDLMF8X3S70',
    'https://www.youtube.com/watch?v=1zG0aHSajxg',
    'https://www.youtube.com/watch?v=oBUqQEJ4RYE',
    'https://www.youtube.com/watch?v=Oot6NmvCWWg',
    'https://www.youtube.com/watch?v=9Rj-5kEqod8',
    'https://www.youtube.com/watch?v=OnK-cx57PPY',
    'https://www.youtube.com/watch?v=QA8vNSFJJXA',
    'https://www.youtube.com/watch?v=lcVx3g3SmmY',
    'https://www.youtube.com/watch?v=k5OrK2g5y70',
    'https://www.youtube.com/watch?v=KcbAhH5TM5o',
    'https://www.youtube.com/watch?v=E5yzQUIZDq8',
    'https://www.youtube.com/watch?v=eoLL906SnLk',
    'https://www.youtube.com/watch?v=JOo-GabaiRY',
    'https://www.youtube.com/watch?v=mNu0Q1wO1VM',
    'https://www.youtube.com/watch?v=GnLU1sZLQR4',
    'https://www.youtube.com/watch?v=OWZ3mtzpn7g',
    'https://www.youtube.com/watch?v=zHRGSrotXcU',
    'https://www.youtube.com/watch?v=ktxjXIPXRFE',
    'https://www.youtube.com/watch?v=6CMLNX4-zdk',
    'https://www.youtube.com/watch?v=f1cNkUkOsto',
    'https://www.youtube.com/watch?v=gOHIH5m_19M',
    'https://www.youtube.com/watch?v=xiSI-Xgrtpo',
    'https://www.youtube.com/watch?v=tfy1cNudP-s',
    'https://www.youtube.com/watch?v=hXJkJorgQHw',
    'https://www.youtube.com/watch?v=g-5PPYDiL2k',
    'https://www.youtube.com/watch?v=JqajfI4-WnM',
    'https://www.youtube.com/watch?v=BITU4r7Zhfs',
    'https://www.youtube.com/watch?v=NSd6zOKZkpI',
    'https://www.youtube.com/watch?v=rUFuU9RTLUo',
    'https://www.youtube.com/watch?v=aPDOZfu_Fyk',
    'https://www.youtube.com/watch?v=JNyp0CuXNDk',
    'https://www.youtube.com/watch?v=aHjgpmzFjOA',
    'https://www.youtube.com/watch?v=_N6SnDSfPIA',
    'https://www.youtube.com/watch?v=VltNcmGvEVo',
    'https://www.youtube.com/watch?v=SxoDCo9iNI0',
    'https://www.youtube.com/watch?v=iKiB5fDglZs',
    'https://www.youtube.com/watch?v=9bwarjtj0po',
    'https://www.youtube.com/watch?v=RoQnxOaTIhY',
    'https://www.youtube.com/watch?v=qaLFU7Wi5Fo',
    'https://www.youtube.com/watch?v=eijFz1N3y2I',
    'https://www.youtube.com/watch?v=Bd42tmCQFN4',
    'https://www.youtube.com/watch?v=mauxf-VsIZA',
    'https://www.youtube.com/watch?v=PooNOW-RqoQ',
    'https://www.youtube.com/watch?v=vjXOxB90ERs',
    'https://www.youtube.com/watch?v=ZFYdZWadyD4',
    'https://www.youtube.com/watch?v=d1uEATa0qIo',
    'https://www.youtube.com/watch?v=2ZHuj8uBinM',
    'https://www.youtube.com/watch?v=SJIPcMgM4G0',
    'https://www.youtube.com/watch?v=9MRmljdyDkY',
    'https://www.youtube.com/watch?v=PX6sS2oV2zM',
    'https://www.youtube.com/watch?v=Of8NAP-1X0c',
    'https://www.youtube.com/watch?v=0KYosqdv0uc',
    'https://www.youtube.com/watch?v=96yW9u78swg',
    'https://www.youtube.com/watch?v=_cohQUYVbrY',
    'https://www.youtube.com/watch?v=4yYytLUViI4',
    'https://www.youtube.com/watch?v=TTD-Cdn166M',
    'https://www.youtube.com/watch?v=wj4h-R-Mgac',
    'https://www.youtube.com/watch?v=SqSePvQ-YAM',
    'https://www.youtube.com/watch?v=mITml5ZpqM8',
    'https://www.youtube.com/watch?v=sbNI_k9P-Y4',
    'https://www.youtube.com/watch?v=mL7sp1wOax4',
    'https://www.youtube.com/watch?v=iaw1iTmozLc',
    'https://www.youtube.com/watch?v=SrrO4OxydO0',
    'https://www.youtube.com/watch?v=TWI-WIoWvfk',
    'https://www.youtube.com/watch?v=8gVMTcPxsYU',
    'https://www.youtube.com/watch?v=aUDNCISQJGo',
    'https://www.youtube.com/watch?v=ZVN8aDVyg1I',
    'https://www.youtube.com/watch?v=z8937RleAZo',
    'https://www.youtube.com/watch?v=s1Hi-wdnXNQ',
    'https://www.youtube.com/watch?v=f4nCMVfNqqM',
    'https://www.youtube.com/watch?v=O7PkxYiyxuU',
    'https://www.youtube.com/watch?v=504F2Go8Suc',
    'https://www.youtube.com/watch?v=ZsH2zc71t78',
    'https://www.youtube.com/watch?v=DsN2kfwkaKg',
    'https://www.youtube.com/watch?v=6jbin15-TcY',
    'https://www.youtube.com/watch?v=hDD3wHo1Ikc',
    'https://www.youtube.com/watch?v=ooc4o2Fu8Tk',
    'https://www.youtube.com/watch?v=wI01INYcaTk',
    'https://www.youtube.com/watch?v=zZp5gSLS1fQ',
    'https://www.youtube.com/watch?v=m66EAgRMmi8',
    'https://www.youtube.com/watch?v=EOV3sAlZ40Q',
    'https://www.youtube.com/watch?v=EHynuNjj1Hg',
    'https://www.youtube.com/watch?v=_WbgaC5d2R0',
    'https://www.youtube.com/watch?v=Fg8s2s2PL5s',
    'https://www.youtube.com/watch?v=ZY-XkxW1e3Y',
    'https://www.youtube.com/watch?v=41wG8NOJ1s8',
    'https://www.youtube.com/watch?v=OjSMc9qKEaY',
    'https://www.youtube.com/watch?v=P3zbg-l-UkI',
    'https://www.youtube.com/watch?v=siJM5pVkxIk',
    'https://www.youtube.com/watch?v=KosFKrMSs1U',
    'https://www.youtube.com/watch?v=B_RFoZ8FTTU',
    'https://www.youtube.com/watch?v=n0wHJW8Z91k',
    'https://www.youtube.com/watch?v=hbLLxRqEJHk',
    'https://www.youtube.com/watch?v=WwlhyxByNuM',
    'https://www.youtube.com/watch?v=wKAVESwlddE',
    'https://www.youtube.com/watch?v=z1MJXJtV97U',
    'https://www.youtube.com/watch?v=Ac6ILoWl8GU',
    'https://www.youtube.com/watch?v=26mohZ65qAU',
    'https://www.youtube.com/watch?v=RfK3D5dJV2Q',
    'https://www.youtube.com/watch?v=CvL-KV3IBcM',
    'https://www.youtube.com/watch?v=3CvMggV6Ryk',
    'https://www.youtube.com/watch?v=z36L1mNS2zY',
    'https://www.youtube.com/watch?v=UWuDgY8aHmU',
    'https://www.youtube.com/watch?v=251r5ja4zJU',
    'https://www.youtube.com/watch?v=yMAO-JVlqUE',
    'https://www.youtube.com/watch?v=ad_ytmEbE3c',
    'https://www.youtube.com/watch?v=n2aNH-x8f_I',
    'https://www.youtube.com/watch?v=PE1auw5oLG8',
    'https://www.youtube.com/watch?v=-ZT57E5iUBU',
    'https://www.youtube.com/watch?v=e1LToi6DTo8',
    'https://www.youtube.com/watch?v=W9f0wxZFeiw',
    'https://www.youtube.com/watch?v=GNjjMLjlF0w',
    'https://www.youtube.com/watch?v=uxZs9YtBZ7Q',
    'https://www.youtube.com/watch?v=eNrzE_UfkTw',
    'https://www.youtube.com/watch?v=ai05XTDM82E',
    'https://www.youtube.com/watch?v=dRcqHzKptT4',
    'https://www.youtube.com/watch?v=VYJvIPqV9Og',
    'https://www.youtube.com/watch?v=UIH0Km4MnkU',
    'https://www.youtube.com/watch?v=1PdOH1vsBiM',
    'https://www.youtube.com/watch?v=NHzDK5CGV_c',
    'https://www.youtube.com/watch?v=qGvB0qno9OY',
    'https://www.youtube.com/watch?v=3P6_zk6FbmE',
    'https://www.youtube.com/watch?v=wru-lL59_Zk',
    'https://www.youtube.com/watch?v=VNfFJpW4YKA',
    'https://www.youtube.com/watch?v=kDE1MAo4kGw',
    'https://www.youtube.com/watch?v=lHQfJsy8klY',
    'https://www.youtube.com/watch?v=T6Y2VjrIA0w',
    'https://www.youtube.com/watch?v=a4qdGUnLXVk',
    'https://www.youtube.com/watch?v=b6naHmO89oo',
    'https://www.youtube.com/watch?v=UXs4ZxKaglg',
    'https://www.youtube.com/watch?v=sREmACrWm3g',
    'https://www.youtube.com/watch?v=W8eWYkrfUuQ',
    'https://www.youtube.com/watch?v=md2MI3K30zQ',
    'https://www.youtube.com/watch?v=zMDm1po0Jwk',
    'https://www.youtube.com/watch?v=iXopZ7A7dM0',
    'https://www.youtube.com/watch?v=hel0ElbGong',
    'https://www.youtube.com/watch?v=WzWhLpRF3gI',
    'https://www.youtube.com/watch?v=q_ehexD_drA',
    'https://www.youtube.com/watch?v=xfR0DJilrFg',
    'https://www.youtube.com/watch?v=lVvTXARkyws',
    'https://www.youtube.com/watch?v=jDlmltgkttA',
    'https://www.youtube.com/watch?v=BgIf3TpUSXM',
    'https://www.youtube.com/watch?v=gOX0lApLtK0',
    'https://www.youtube.com/watch?v=nRYz_PbMB7k',
    'https://www.youtube.com/watch?v=qVk5uz33aLk',
    'https://www.youtube.com/watch?v=5PjeLuNJC3Y',
    'https://www.youtube.com/watch?v=6_CLqV1Gy2Q',
    'https://www.youtube.com/watch?v=pl1gCcSgdIo',
    'https://www.youtube.com/watch?v=sqf79JDY83A',
    'https://www.youtube.com/watch?v=gMLHFYWeEWw',
    'https://www.youtube.com/watch?v=JBoMG3QoAXU',
    'https://www.youtube.com/watch?v=f8VEdVVjnjk',
    'https://www.youtube.com/watch?v=o7BJEqyrDm4',
    'https://www.youtube.com/watch?v=eqFtJAZ-BQQ',
    'https://www.youtube.com/watch?v=0WkSXS7Y5dY',
    'https://www.youtube.com/watch?v=KvFDb1_nezM',
    'https://www.youtube.com/watch?v=MdtbH7UHNJM',
    'https://www.youtube.com/watch?v=q2hS57dGmFw',
    'https://www.youtube.com/watch?v=QbiB0A5jqqY',
    'https://www.youtube.com/watch?v=20hECe2hSfY',
    'https://www.youtube.com/watch?v=Z3PSSJM7J9U',
    'https://www.youtube.com/watch?v=UyJvV0cxKmA',
    'https://www.youtube.com/watch?v=AidrN9rK-II',
    'https://www.youtube.com/watch?v=QT2xj9k00q0',
    'https://www.youtube.com/watch?v=XoUbeCHujPI',
    'https://www.youtube.com/watch?v=O03erV5nYXA',
    'https://www.youtube.com/watch?v=i__0cG4ijrI',
    'https://www.youtube.com/watch?v=Cy_2wZJrgfw',
    'https://www.youtube.com/watch?v=aWC1NUo0Cwk',
    'https://www.youtube.com/watch?v=0GM0sEvQ2-M',
    'https://www.youtube.com/watch?v=woy7_L2JKC4',
    'https://www.youtube.com/watch?v=OJy2h9mgiX8',
    'https://www.youtube.com/watch?v=IHRqGoFvCyw',
    'https://www.youtube.com/watch?v=6QjSQBvNLdQ',
    'https://www.youtube.com/watch?v=budPMNQ-qfQ',
    'https://www.youtube.com/watch?v=ZTzyWkdQMjg',
    'https://www.youtube.com/watch?v=ZdkPLgQptYI',
    'https://www.youtube.com/watch?v=c3PHRGCerwc',
    'https://www.youtube.com/watch?v=zI5NS1b3wio',
    'https://www.youtube.com/watch?v=ayZXCy6Vc5o',
    'https://www.youtube.com/watch?v=7n0HTtThMe0',
    'https://www.youtube.com/watch?v=ywgNjdIW_34',
    'https://www.youtube.com/watch?v=G7C6MToa4jo',
    'https://www.youtube.com/watch?v=U1KrPJ-gakY',
    'https://www.youtube.com/watch?v=avtVbH2rdg0',
    'https://www.youtube.com/watch?v=UUaaoK8Fqkc',
    'https://www.youtube.com/watch?v=-_1p3xVhzvM',
    'https://www.youtube.com/watch?v=uqRYfAX_2z0',
    'https://www.youtube.com/watch?v=wQSSNVRaFag',
    'https://www.youtube.com/watch?v=LH3vvA7PL1U',
    'https://www.youtube.com/watch?v=OoNSL2xAaOM',
    'https://www.youtube.com/watch?v=G5jlJ_JHg_k',
    'https://www.youtube.com/watch?v=1Z-42hz9U-w',
    'https://www.youtube.com/watch?v=ARI363zQkGg',
    'https://www.youtube.com/watch?v=uvsdpMSabLU',
    'https://www.youtube.com/watch?v=7QwQgVJGFPg',
    'https://www.youtube.com/watch?v=86EFFErWfhM',
    'https://www.youtube.com/watch?v=30WYArVue7g',
    'https://www.youtube.com/watch?v=UoBrc4983U0',
    'https://www.youtube.com/watch?v=vFRjUD6CVzo',
    'https://www.youtube.com/watch?v=7Wb2o8ZA8Gg',
    'https://www.youtube.com/watch?v=FsTu3bNVynE',
    'https://www.youtube.com/watch?v=5l2JYKvcCXQ',
    'https://www.youtube.com/watch?v=rNeZdjmLass',
    'https://www.youtube.com/watch?v=HkLgdCGplkg',
    'https://www.youtube.com/watch?v=b2J93oxmVfg',
    'https://www.youtube.com/watch?v=gxin3BLshUA',
    'https://www.youtube.com/watch?v=FzHjFzApADY',
    'https://www.youtube.com/watch?v=OL4bnmbzZ4M',
    'https://www.youtube.com/watch?v=I6UgeIY9Tqc',
    'https://www.youtube.com/watch?v=wEoCavGqPX4',
    'https://www.youtube.com/watch?v=yR4Su0_LPQg',
    'https://www.youtube.com/watch?v=qH89VbfKJAg',
    'https://www.youtube.com/watch?v=km9X6kVis-E',
    'https://www.youtube.com/watch?v=_wUOcDkxAzE',
    'https://www.youtube.com/watch?v=2ENW8u2eP50',
    'https://www.youtube.com/watch?v=5rdeqzLQ92Q',
    'https://www.youtube.com/watch?v=ZT_V0-GuCjs',
    'https://www.youtube.com/watch?v=S-hDy0NZqwg',
    'https://www.youtube.com/watch?v=lCxYejIzJus',
    'https://www.youtube.com/watch?v=i1CnXo74yxo',
    'https://www.youtube.com/watch?v=q1XvZcYxXTg',
    'https://www.youtube.com/watch?v=DExRRlqw_pw',
    'https://www.youtube.com/watch?v=HKSrEEK7dpc',
    'https://www.youtube.com/watch?v=9d6miyrBvKw',
    'https://www.youtube.com/watch?v=LrK-QQest0c',
    'https://www.youtube.com/watch?v=TPS0pD4-t-I',
    'https://www.youtube.com/watch?v=XHxWAspGCyQ',
    'https://www.youtube.com/watch?v=3lnVBqxjC88',
    'https://www.youtube.com/watch?v=ZfuOw02U7hs',
    'https://www.youtube.com/watch?v=p118LpI228s',
    'https://www.youtube.com/watch?v=-k1gbi3JrCA',
    'https://www.youtube.com/watch?v=qDTj_XLoNAE',
    'https://www.youtube.com/watch?v=JqDAfBjQj8o',
    'https://www.youtube.com/watch?v=qfZKbffgvLQ',
    'https://www.youtube.com/watch?v=38rbYmxgIFc',
    'https://www.youtube.com/watch?v=CN3D6zIMWWs',
    'https://www.youtube.com/watch?v=l1iSbsQjWxo',
    'https://www.youtube.com/watch?v=32BFk113CW0',
    'https://www.youtube.com/watch?v=18_KQK3MO3U',
    'https://www.youtube.com/watch?v=revNgAPjcrM',
    'https://www.youtube.com/watch?v=5-vWptZ6kNo',
    'https://www.youtube.com/watch?v=gPSt-xs_zWQ',
    'https://www.youtube.com/watch?v=Jvmf46Rq3n4',
    'https://www.youtube.com/watch?v=9zH--IngYCQ',
    'https://www.youtube.com/watch?v=qVo9oApl4Rs',
    'https://www.youtube.com/watch?v=RJKYUBB0l6s',
    'https://www.youtube.com/watch?v=oPLm0T1Np0s',
    'https://www.youtube.com/watch?v=xCwEWnlczZA',
    'https://www.youtube.com/watch?v=iKUA_XtTCiE',
    'https://www.youtube.com/watch?v=dKyKjqRXneM',
    'https://www.youtube.com/watch?v=yAYMyqZmZOk',
    'https://www.youtube.com/watch?v=OQVMpHRojdw',
    'https://www.youtube.com/watch?v=L5C2WLuuvfk',
    'https://www.youtube.com/watch?v=fKvVPffcC-Y',
    'https://www.youtube.com/watch?v=vjxwTpOMCKI',
    'https://www.youtube.com/watch?v=RphuVZyf9eA',
    'https://www.youtube.com/watch?v=Vb0CTAB4Ym4',
    'https://www.youtube.com/watch?v=KUYpvBlAwLE',
    'https://www.youtube.com/watch?v=anEs-VKDqIs',
    'https://www.youtube.com/watch?v=OVE_mjp3Fxs',
    'https://www.youtube.com/watch?v=1HW3ZvG53Ug',
    'https://www.youtube.com/watch?v=00WeQePLcns',
    'https://www.youtube.com/watch?v=Medrs44pApI',
    'https://www.youtube.com/watch?v=DEzPghVPPgE',
    'https://www.youtube.com/watch?v=_GjVijUniv8',
    'https://www.youtube.com/watch?v=XuPdt0cMSu0',
    'https://www.youtube.com/watch?v=gcfKvy4NrOE',
    'https://www.youtube.com/watch?v=MsMe1G3UbMI',
    'https://www.youtube.com/watch?v=fkzKfK2eEqs',
    'https://www.youtube.com/watch?v=LRqX5uO5StA',
    'https://www.youtube.com/watch?v=-Q1rTdmGI3k',
    'https://www.youtube.com/watch?v=xQSu1vQiwFM',
    'https://www.youtube.com/watch?v=Bh3QH4aCO2Q',
    'https://www.youtube.com/watch?v=nHXO43BqeQw',
    'https://www.youtube.com/watch?v=7pibisWRncY',
    'https://www.youtube.com/watch?v=sCI0RriNadY',
    'https://www.youtube.com/watch?v=hq3icSNa2ns',
    'https://www.youtube.com/watch?v=IjS2sVPR2Zc',
    'https://www.youtube.com/watch?v=BaKyxTmakd0',
    'https://www.youtube.com/watch?v=YNOxyqLkimE',
    'https://www.youtube.com/watch?v=-n8oRSpm_is',
    'https://www.youtube.com/watch?v=hB1cbPxXqhU',
    'https://www.youtube.com/watch?v=Ha32LmYLmrU',
    'https://www.youtube.com/watch?v=_wlAf0SSfqc',
    'https://www.youtube.com/watch?v=CnKmNENbLYM',
    'https://www.youtube.com/watch?v=BGUEyfmUgiQ',
    'https://www.youtube.com/watch?v=wCle_ARznj4',
    'https://www.youtube.com/watch?v=QnaBao5QKro',
    'https://www.youtube.com/watch?v=EbETMvEgvHE',
    'https://www.youtube.com/watch?v=nVF2OiUHmx0',
    'https://www.youtube.com/watch?v=twTV8uwYIes',
    'https://www.youtube.com/watch?v=GSzkxD64Cic',
    'https://www.youtube.com/watch?v=vwRE1kN2oR4',
    'https://www.youtube.com/watch?v=eLwnCDyrZxI',
    'https://www.youtube.com/watch?v=w8nAf47ypaw',
    'https://www.youtube.com/watch?v=lLH70qkROWQ',
    'https://www.youtube.com/watch?v=5m3djtMGyHs',
    'https://www.youtube.com/watch?v=jFH3d3GYwHU',
    'https://www.youtube.com/watch?v=91M3SiSmLn0',
    'https://www.youtube.com/watch?v=WIq9gae1YJw',
    'https://www.youtube.com/watch?v=zv_SbEk6G2w',
    'https://www.youtube.com/watch?v=2xWv0hFK8oc',
    'https://www.youtube.com/watch?v=c9jJVYTJkFE',
    'https://www.youtube.com/watch?v=8CIxMH_DnX4',
    'https://www.youtube.com/watch?v=LUeW8lS2zs4',
    'https://www.youtube.com/watch?v=TLIFE3br67o',
    'https://www.youtube.com/watch?v=bhOGgAahnQw',
    'https://www.youtube.com/watch?v=jPeKeAp2Hj0',
    'https://www.youtube.com/watch?v=_Z2TDMXTVLc',
    'https://www.youtube.com/watch?v=-YNDnccxnQA',
    'https://www.youtube.com/watch?v=ktZLuXPXPEI',
    'https://www.youtube.com/watch?v=tFepMmoH9ng',
    'https://www.youtube.com/watch?v=B_imlyArr_0',
    'https://www.youtube.com/watch?v=nFGLmuG2cOk',
    'https://www.youtube.com/watch?v=y8D8CBvs6iY',
    'https://www.youtube.com/watch?v=7rT1O3fGDVs',
    'https://www.youtube.com/watch?v=OCv4Q3zA22g',
    'https://www.youtube.com/watch?v=KYgG72oQhOw',
    'https://www.youtube.com/watch?v=31M8SGez90E',
    'https://www.youtube.com/watch?v=pJtw6IRo9q4',
    'https://www.youtube.com/watch?v=eNpdvzORWVc',
    'https://www.youtube.com/watch?v=-NSoSCwwo-s',
    'https://www.youtube.com/watch?v=vsA4w3itxA0',
    'https://www.youtube.com/watch?v=y_CAfq5JlUc',
    'https://www.youtube.com/watch?v=5J8pabP3FBY',
    'https://www.youtube.com/watch?v=r_1Qwgufiz0',
    'https://www.youtube.com/watch?v=XV0cc67NYgI',
    'https://www.youtube.com/watch?v=9tKr6dTYFmY',
    'https://www.youtube.com/watch?v=fkkJEVD-ugA',
    'https://www.youtube.com/watch?v=iS_6vCNSuP8',
    'https://www.youtube.com/watch?v=rTeqJigQoaU',
    'https://www.youtube.com/watch?v=RJk8Jd9N1Ho',
    'https://www.youtube.com/watch?v=1NlfIG3sUBM',
    'https://www.youtube.com/watch?v=nRXyueJf-jA',
    'https://www.youtube.com/watch?v=RbkhWrTbrKs',
    'https://www.youtube.com/watch?v=KIrrA1-O6LE'
  ]},
  'NIMHgov': {'channel': 'https://www.youtube.com/user/NIMHgov/videos',
  'title': 'NIMHgov',
  'video_urls': ['https://www.youtube.com/watch?v=m9M23WDpjwc',
    'https://www.youtube.com/watch?v=00Pl3xIJxu0',
    'https://www.youtube.com/watch?v=CNxEjT2hMiU',
    'https://www.youtube.com/watch?v=FCaLJN2d1zM',
    'https://www.youtube.com/watch?v=l26hdCD9g2I',
    'https://www.youtube.com/watch?v=2OfNPiZz3Lw',
    'https://www.youtube.com/watch?v=Q3tTIxUTJ2E',
    'https://www.youtube.com/watch?v=Pz6tWA2HCss',
    'https://www.youtube.com/watch?v=mqt-8qdoDj0',
    'https://www.youtube.com/watch?v=CfaF_AhG41s',
    'https://www.youtube.com/watch?v=atCb8NGFsu8',
    'https://www.youtube.com/watch?v=uZPfVnogYSw',
    'https://www.youtube.com/watch?v=2g16BwpRRWc',
    'https://www.youtube.com/watch?v=awO2ieInjVk',
    'https://www.youtube.com/watch?v=xwuWI3IVaTU',
    'https://www.youtube.com/watch?v=BCm3thGnBjw',
    'https://www.youtube.com/watch?v=YzDMl9cxwe8',
    'https://www.youtube.com/watch?v=Z-3qqJhSetc',
    'https://www.youtube.com/watch?v=N91vw3smkgU',
    'https://www.youtube.com/watch?v=9aHTHGjQ628',
    'https://www.youtube.com/watch?v=bQMURCW53lc',
    'https://www.youtube.com/watch?v=yblmY7JUv8M',
    'https://www.youtube.com/watch?v=G5ZDOflLhW0',
    'https://www.youtube.com/watch?v=zKBO2aqVy3c',
    'https://www.youtube.com/watch?v=3xbD33yt7Xs',
    'https://www.youtube.com/watch?v=QJ4RRuZ07n4',
    'https://www.youtube.com/watch?v=7jdYj6_-OG0',
    'https://www.youtube.com/watch?v=HCx_ePbVA1o',
    'https://www.youtube.com/watch?v=ecJndtn83Tc',
    'https://www.youtube.com/watch?v=CQiQ0yiFQo0',
    'https://www.youtube.com/watch?v=2FDePd4G1T4',
    'https://www.youtube.com/watch?v=E2dZzhGGZvA',
    'https://www.youtube.com/watch?v=GQzaF2sQTPg',
    'https://www.youtube.com/watch?v=PshlCnBb3ok',
    'https://www.youtube.com/watch?v=wMuwc2MxLuw',
    'https://www.youtube.com/watch?v=Sjm3bj5ulYE',
    'https://www.youtube.com/watch?v=Ma6ALpRQpH4',
    'https://www.youtube.com/watch?v=i6zJCI4CIDQ',
    'https://www.youtube.com/watch?v=3NgE8u0jAtw',
    'https://www.youtube.com/watch?v=IJuy7E4RC6g',
    'https://www.youtube.com/watch?v=h8oyZwyDZrE',
    'https://www.youtube.com/watch?v=4l46wm1Ra6I',
    'https://www.youtube.com/watch?v=ndJucSiRIv0',
    'https://www.youtube.com/watch?v=nM3ObrdUO8E',
    'https://www.youtube.com/watch?v=iGIf_EXmIVI',
    'https://www.youtube.com/watch?v=a-EXkYETaCg',
    'https://www.youtube.com/watch?v=lP5TDuMnewM',
    'https://www.youtube.com/watch?v=abfNVeXcMt0',
    'https://www.youtube.com/watch?v=N6g_TpQsL0I',
    'https://www.youtube.com/watch?v=tR4ulH4vB-Y',
    'https://www.youtube.com/watch?v=Adh_q1PIK3A',
    'https://www.youtube.com/watch?v=3ZgMCdFHOFA',
    'https://www.youtube.com/watch?v=cnHhlFVBcJc',
    'https://www.youtube.com/watch?v=SDaHFnpsWzE',
    'https://www.youtube.com/watch?v=OsBPw8xEFRg',
    'https://www.youtube.com/watch?v=_lJbWkkGRpY',
    'https://www.youtube.com/watch?v=T9ZeL3958cM',
    'https://www.youtube.com/watch?v=PKj9i1qS08M',
    'https://www.youtube.com/watch?v=T53kk0bOZag',
    'https://www.youtube.com/watch?v=UN5MLb8XRQ0',
    'https://www.youtube.com/watch?v=E5HfKGyE3Y8',
    'https://www.youtube.com/watch?v=2aU0dMYTqEE',
    'https://www.youtube.com/watch?v=usI6PDwMjcw',
    'https://www.youtube.com/watch?v=7S3FfBhFMTY',
    'https://www.youtube.com/watch?v=i_RV0oMFdGc',
    'https://www.youtube.com/watch?v=PT2z49biG28',
    'https://www.youtube.com/watch?v=_Cb8ZiYqVuo',
    'https://www.youtube.com/watch?v=x3OUQ093bNM',
    'https://www.youtube.com/watch?v=_4Qzi83d_AA',
    'https://www.youtube.com/watch?v=9d73P1NGnLo',
    'https://www.youtube.com/watch?v=VYwOg0sSfoo',
    'https://www.youtube.com/watch?v=LnLZBRhmHkQ',
    'https://www.youtube.com/watch?v=28NE0f1Qy8A',
    'https://www.youtube.com/watch?v=AQqG2oikEng',
    'https://www.youtube.com/watch?v=zRuUQiIgyj4',
    'https://www.youtube.com/watch?v=QRvdQ_FzvUs',
    'https://www.youtube.com/watch?v=iUYQaog7vEU',
    'https://www.youtube.com/watch?v=UqNQ8KRqNSA',
    'https://www.youtube.com/watch?v=il42VO606GA',
    'https://www.youtube.com/watch?v=FiSYcjT1cU0',
    'https://www.youtube.com/watch?v=dQnsbBXNA4Q',
    'https://www.youtube.com/watch?v=3cAxlcyavGg',
    'https://www.youtube.com/watch?v=hOrR6CpRLCw',
    'https://www.youtube.com/watch?v=0hV1lUbC8mE',
    'https://www.youtube.com/watch?v=Yqtp9M5cc0A',
    'https://www.youtube.com/watch?v=94F7DVkb0yQ',
    'https://www.youtube.com/watch?v=q2J4ZxIrKxA',
    'https://www.youtube.com/watch?v=WPtmu8wLidU',
    'https://www.youtube.com/watch?v=yVBc6G52Xqs',
    'https://www.youtube.com/watch?v=-78xCv9GzW4',
    'https://www.youtube.com/watch?v=p-I8eW6SNpY',
    'https://www.youtube.com/watch?v=MzgKxgrfbNs',
    'https://www.youtube.com/watch?v=ujQbITLxvIA',
    'https://www.youtube.com/watch?v=IgCUVivTwMI',
    'https://www.youtube.com/watch?v=khaAK2_c7sc',
    'https://www.youtube.com/watch?v=wGBHPrgwJ5Q',
    'https://www.youtube.com/watch?v=JxCXKjhI7CA',
    'https://www.youtube.com/watch?v=Ik3qMFWQ9Mg',
    'https://www.youtube.com/watch?v=lpyKSYC_fF8',
    'https://www.youtube.com/watch?v=i9s4rlOYM9Q',
    'https://www.youtube.com/watch?v=ARzDocGh_HQ',
    'https://www.youtube.com/watch?v=lwvsvIPZLUI',
    'https://www.youtube.com/watch?v=qoTXQ88Br9M',
    'https://www.youtube.com/watch?v=-2sSvJ0tcSE',
    'https://www.youtube.com/watch?v=MKCwPJeQK4k',
    'https://www.youtube.com/watch?v=lI9d4CBsGgg',
    'https://www.youtube.com/watch?v=3QI3Fm_gzz0',
    'https://www.youtube.com/watch?v=VyGVDrIqRKw',
    'https://www.youtube.com/watch?v=5EA_J9iuBpQ',
    'https://www.youtube.com/watch?v=3joK-Ocvm7c',
    'https://www.youtube.com/watch?v=JrtX4EURcnM',
    'https://www.youtube.com/watch?v=z4let-_D-FQ',
    'https://www.youtube.com/watch?v=aJ52vPhn9Cc',
    'https://www.youtube.com/watch?v=FpG4-gvOo9o',
    'https://www.youtube.com/watch?v=mlNCavst2EU',
    'https://www.youtube.com/watch?v=stPThgZ2Y5o',
    'https://www.youtube.com/watch?v=ChuYl2YzNUI',
    'https://www.youtube.com/watch?v=9QexrqfcFN0',
    'https://www.youtube.com/watch?v=QG29hbQV54k',
    'https://www.youtube.com/watch?v=fWgKAzA02cg',
    'https://www.youtube.com/watch?v=Gnm8f76zx0g',
    'https://www.youtube.com/watch?v=jeji27jrq7M',
    'https://www.youtube.com/watch?v=8aRaub3ossE',
    'https://www.youtube.com/watch?v=sNB6C2Bll00',
    'https://www.youtube.com/watch?v=5262XX-K4Xs',
    'https://www.youtube.com/watch?v=tMpcrTiRDo0',
    'https://www.youtube.com/watch?v=IkeCj2VOjX4',
    'https://www.youtube.com/watch?v=MP3hsGVxCfM',
    'https://www.youtube.com/watch?v=lKnfaaG0h_0',
    'https://www.youtube.com/watch?v=WtczEbcvehM',
    'https://www.youtube.com/watch?v=w2rYnbYFdTw',
    'https://www.youtube.com/watch?v=BeFoeBfKKL0',
    'https://www.youtube.com/watch?v=dwFBciz1k-I',
    'https://www.youtube.com/watch?v=KSOHkzle28k',
    'https://www.youtube.com/watch?v=kKEG6yK-KsQ',
    'https://www.youtube.com/watch?v=qyY_eSl-RDg',
    'https://www.youtube.com/watch?v=WE272T-0o6A',
    'https://www.youtube.com/watch?v=OyGt8-ddacA',
    'https://www.youtube.com/watch?v=K4PK_UUD12M',
    'https://www.youtube.com/watch?v=C4Xup5nli6g',
    'https://www.youtube.com/watch?v=0WmfqiN3Sw4',
    'https://www.youtube.com/watch?v=pQKY-JVs0PA',
    'https://www.youtube.com/watch?v=zNnP1qZJnVI',
    'https://www.youtube.com/watch?v=HWpZ1i-KojI',
    'https://www.youtube.com/watch?v=4vkUhG_Y20g',
    'https://www.youtube.com/watch?v=_0pizI5jNL4',
    'https://www.youtube.com/watch?v=CySDbTH46P4',
    'https://www.youtube.com/watch?v=z6idLnw4DY8',
    'https://www.youtube.com/watch?v=Tb6euCVoous',
    'https://www.youtube.com/watch?v=mWY64o6SeE8',
    'https://www.youtube.com/watch?v=ivNnl3SW1Jo',
    'https://www.youtube.com/watch?v=7qpUaFj3nB8',
    'https://www.youtube.com/watch?v=ht_CxcCPd8I',
    'https://www.youtube.com/watch?v=cDUxMKKe0AA',
    'https://www.youtube.com/watch?v=qBrqD8bXS8g',
    'https://www.youtube.com/watch?v=mmxkqOUMqkM',
    'https://www.youtube.com/watch?v=B3Jv16KsAwE',
    'https://www.youtube.com/watch?v=7h6Hwn9loVk',
    'https://www.youtube.com/watch?v=8SDKV29NPaE',
    'https://www.youtube.com/watch?v=IvKcS2a5Adg',
    'https://www.youtube.com/watch?v=P4_-SF9lQuc',
    'https://www.youtube.com/watch?v=09SCcS-Jjpg',
    'https://www.youtube.com/watch?v=YhbQgrh1aLU',
    'https://www.youtube.com/watch?v=1R6-gLZZhYc',
    'https://www.youtube.com/watch?v=yKABcJcptBI',
    'https://www.youtube.com/watch?v=_1I-bQcNqgo',
    'https://www.youtube.com/watch?v=81DWzCMPhC4',
    'https://www.youtube.com/watch?v=yc9TS89qxlQ',
    'https://www.youtube.com/watch?v=J46Ysc1O50Y',
    'https://www.youtube.com/watch?v=L1MEvzJQLOE',
    'https://www.youtube.com/watch?v=IgCL79Jv0lc',
    'https://www.youtube.com/watch?v=-VRFZpJuWF4',
    'https://www.youtube.com/watch?v=YqsfgMZ0ZtM',
    'https://www.youtube.com/watch?v=NDcjynH5iwo',
    'https://www.youtube.com/watch?v=L-eGNAkxRe0',
    'https://www.youtube.com/watch?v=Fui2tLzALJc',
    'https://www.youtube.com/watch?v=G61qVbqB6ns',
    'https://www.youtube.com/watch?v=5cEifeam4Qw',
    'https://www.youtube.com/watch?v=pvpB1G0Hv44',
    'https://www.youtube.com/watch?v=_2jPCAZbtXA',
    'https://www.youtube.com/watch?v=onNmm-aJfU0',
    'https://www.youtube.com/watch?v=n9YaEstN94c',
    'https://www.youtube.com/watch?v=tZuJL6U7fFk',
    'https://www.youtube.com/watch?v=-nZcSag7E5s',
    'https://www.youtube.com/watch?v=8D59vM54MuM',
    'https://www.youtube.com/watch?v=VziPQCHnpuY',
    'https://www.youtube.com/watch?v=25MK8Dft7Jo',
    'https://www.youtube.com/watch?v=rkmF5ngCouM',
    'https://www.youtube.com/watch?v=ylYbThHWl5U',
    'https://www.youtube.com/watch?v=2EdwQqo0T0Y',
    'https://www.youtube.com/watch?v=nKMEcb2fUoM',
    'https://www.youtube.com/watch?v=MsDL2yJsz2g',
    'https://www.youtube.com/watch?v=XeIvtx6HHLg',
    'https://www.youtube.com/watch?v=LYgOxldodeg',
    'https://www.youtube.com/watch?v=Hz6w3CUkhHU',
    'https://www.youtube.com/watch?v=O37THWhGOis',
    'https://www.youtube.com/watch?v=fVZ8TAARObw',
    'https://www.youtube.com/watch?v=_yTzJIKmcLQ',
    'https://www.youtube.com/watch?v=ewHrW2IFJ68',
    'https://www.youtube.com/watch?v=a6_gguD6D6E',
    'https://www.youtube.com/watch?v=64_nOyb-7_g',
    'https://www.youtube.com/watch?v=7KiihIE0d0c',
    'https://www.youtube.com/watch?v=qy1giPm2sr4',
    'https://www.youtube.com/watch?v=kDPDyLJAQ8k',
    'https://www.youtube.com/watch?v=AY6l6Du8qA4',
    'https://www.youtube.com/watch?v=d356-TZB58I',
    'https://www.youtube.com/watch?v=i7QsjMqOdjg',
    'https://www.youtube.com/watch?v=qf-wm8pfpio',
    'https://www.youtube.com/watch?v=UPzdAhTxGIc',
    'https://www.youtube.com/watch?v=EUx8-xesL6M',
    'https://www.youtube.com/watch?v=blGspbRP740',
    'https://www.youtube.com/watch?v=n6_PoBQB0M4',
    'https://www.youtube.com/watch?v=fN0G2Nqn43k',
    'https://www.youtube.com/watch?v=GQo1Wz118lo',
    'https://www.youtube.com/watch?v=VebvCU0rb3g',
    'https://www.youtube.com/watch?v=gg78tzV25aw',
    'https://www.youtube.com/watch?v=w3BGQwHVdd8',
    'https://www.youtube.com/watch?v=4T8h_UY0NEU',
    'https://www.youtube.com/watch?v=7CDZR4qm2HE',
    'https://www.youtube.com/watch?v=1TlfVx2m7RA',
    'https://www.youtube.com/watch?v=m9_7hKjABIE',
    'https://www.youtube.com/watch?v=9bCulDExyug',
    'https://www.youtube.com/watch?v=5EfoqT9kPmI',
    'https://www.youtube.com/watch?v=6kaCdrvNGZw',
    'https://www.youtube.com/watch?v=Rt938F08d7c',
    'https://www.youtube.com/watch?v=uUGzbcLT1eE',
    'https://www.youtube.com/watch?v=wjNxHJM5hTg',
    'https://www.youtube.com/watch?v=4eI_AWaZ4KU',
    'https://www.youtube.com/watch?v=qdRY8i8zO2E',
    'https://www.youtube.com/watch?v=egcMtIwDPrw',
    'https://www.youtube.com/watch?v=m6B7mNc54ZU',
    'https://www.youtube.com/watch?v=WUB17jjdLM0',
    'https://www.youtube.com/watch?v=zbUl2hZNlKY',
    'https://www.youtube.com/watch?v=zl6R6w1WvZk',
    'https://www.youtube.com/watch?v=gK3dcjBaJyo'
]}}

def search_in_oer_collection(key):
    if key not in oer_collections:
        return []
    urls = oer_collections[key]['video_urls']
    return [ o.data_and_id() for o in Oer.query.filter(Oer.url.in_(urls)).order_by(Oer.id).all() ]
