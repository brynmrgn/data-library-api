# config/initializers/resource_config.rb
RESOURCE_CONFIG = {
  deposited_papers: {
    route_path: 'deposited-papers',
    controller_name: 'deposited_papers',
    model_class: 'DepositedPaper'
  },
  research_briefings: {
    route_path: 'research-briefings',
    controller_name: 'research_briefings',
    model_class: 'ResearchBriefing'
  }
}.freeze