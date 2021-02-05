AGES = list(
    name='age-groups',
    shortName='age',
    label='Age',
    choices=c(
        age1='13-24 years',
        age2='25-34 years',
        age3='35-44 years',
        age4='45-54 years',
        age5='55+ years') )

RACES = list(
    name='racial-groups',
    shortName='race',
    label='Race',
    choices=c(
        black="Black",
        hispanic="Hispanic",
        other="Other") )

SEXES = list(
    name='sex',
    shortName='sex',
    label='Sex',
    choices=c(
        male='Male',
        female='Female') )

RISKS = list(
    name='risk-groups',
    shortName='risk',
    label='Risk Factor',
    choices=c(
        msm="MSM",
        idu="IDU",
        msm_idu="MSM+IDU",
        heterosexual="Heterosexual") )

RISKS2 = list(
    name='risk-groups',
    shortName='risk',
    label='Risk Factor',
    choices=c(
        msm="MSM",
        iduActive="Active IDU",
        iduPrior="Prior IDU",
        msm_iduActive="MSM + active IDU",
        msm_iduPrior="MSM + prior IDU",
        heterosexual="Heterosexual") )